class_name TamerInput
extends Node
## Mouse and keys to commands, by mode (BattleMode). Exploring: LMB walks the trainer (hold to keep walking; on a
## starter in the opening it picks it), RMB on a wild creature starts a battle with it. In battle you control your
## creature: LMB moves it (hold to keep moving), RMB attacks the creature under the cursor (or swings toward the
## cursor), Space is its dodge. Always: Q W E R and T aim while held and fire on release, 1-6 swap, Z V items,
## F Sync Lens (the trainer scans a weakened or staggered creature), C camp, I creature info, F1 (dev) a shiny.
## The pointer can be the real mouse or a test's virtual cursor.

const REPATH: float = 0.12
const PICK_PAD: float = 14.0

var g: TamerGame
var cursor_override: Vector2 = Vector2.INF
var hovered: Creature
var _held: bool = false
var _rmb_held: bool = false
var _repath: float = 0.0


func setup(game: TamerGame) -> void:
	g = game


func cursor() -> Vector2:
	return cursor_override if cursor_override != Vector2.INF else g.get_global_mouse_position()


func _unhandled_input(event: InputEvent) -> void:
	if g.hud.panel_open() and event.is_action_pressed("menu"):
		if g.hud.sanctuary.visible:
			g.hud.sanctuary.close()
		elif g.hud.info_panel.visible:
			g.hud.info_panel.close()
		else:
			g.hud.camp_panel.close()
		return
	if event.is_action_pressed("click"):
		_held = true
		press()
	elif event.is_action_released("click"):
		_held = false
	elif event.is_action_pressed("slot_rmb"):
		_rmb_held = true
		attack()
	elif event.is_action_released("slot_rmb"):
		_rmb_held = false
	else:
		_keys(event)


func _keys(event: InputEvent) -> void:
	if event.is_action_pressed("dash"):
		dodge()
	elif event.is_action_pressed("bond_move"):
		start_aim(-1)
	elif event.is_action_released("bond_move"):
		release_aim(-1)
	elif event.is_action_pressed("inventory"):
		g.hud.info_panel.toggle(g.team.current())
	elif event.is_action_pressed("item_berry"):
		g.field.use_item("berry")
	elif event.is_action_pressed("item_salts"):
		g.field.use_item("salts")
	elif event.is_action_pressed("retreat") and g.battle.on:
		g.battle.end(false)
	elif event.is_action_pressed("dev_shiny"):
		g.spawner.spawn_shiny_near(g.trainer.global_position)
	elif event.is_action_pressed("interact"):
		g.lens.request()
	elif event.is_action_pressed("camp") and g.camp.resting:
		g.hud.camp_panel.toggle()
	for i: int in TamerKeys.SWAPS.size():
		if event.is_action_pressed(TamerKeys.SWAPS[i]) and g.field.swap(i):
			g.guide.done("swap")
	for i: int in TamerKeys.MOVE_SLOTS.size():
		if event.is_action_pressed(TamerKeys.MOVE_SLOTS[i]):
			start_aim(i)
		elif event.is_action_released(TamerKeys.MOVE_SLOTS[i]):
			release_aim(i)


## LMB pressed at the cursor: walk (the trainer exploring, your creature in battle). It never attacks.
func press() -> void:
	if g.meeting != null and hovered != null and hovered.side == StarterMeeting.SIDE:
		g.meeting.pick(hovered)
		return
	_move_to(cursor())


func _move_to(p: Vector2) -> void:
	if g.battle.on and g.battle.brain() != null:
		g.battle.brain().goal = p
		g.battle.brain().target = null
	else:
		g.lens.cancel()
		g.trainer.walk_to(p)


## RMB: exploring, a wild creature under the cursor starts a battle with it. In battle, your creature goes for the
## creature under the cursor, or swings its basic attack toward the cursor.
func attack() -> void:
	var foe: Creature = hovered if hovered != null and hovered.side == Combatant.SIDE_WILD else null
	if not g.battle.on:
		if foe != null:
			g.battle.engage(foe)
			_mark(foe)
		return
	var b: ControlledBrain = g.battle.brain()
	if b == null:
		return
	b.goal = Vector2.INF
	b.target = foe
	if foe != null:
		_mark(foe)
	elif g.field.partner != null:
		g.field.partner.cast(String(g.field.partner.rec.data()["basic"]), cursor())


func _mark(foe: Creature) -> void:
	Fx.ring(g.fx_layer, foe.global_position, foe.hit_radius() * 2.5, foe.hit_radius() * 1.2, Pal.c("gold"), 0.25)
	Audio.sfx("ui_click", -10.0, 1.4)


## A move key goes down: if the gauge can pay for it, time slows (SlowTime) and a ghost shows where it will land.
func start_aim(i: int) -> void:
	var p: Creature = g.field.partner
	if p == null or not p.alive():
		return
	if i < 0 and not p.rec.bond_move_ready():
		g.hud.notice("Fight together to fill the bond meter first")
		return
	var id: String = p.rec.bond_move() if i < 0 else String(p.rec.moves()[i])
	var cost: int = int(TamerData.move(id).get("cost", 0))
	if g.team.gauge + 0.001 < float(cost):
		g.hud.gauge_short(cost)
		return
	g.aim.aim(p, id)
	g.slow.begin()


## The key comes up: time returns, the gauge is spent and the move goes off at the cursor.
func release_aim(_i: int) -> void:
	if not g.aim.aiming():
		return
	var id: String = g.aim.move_id
	g.aim.clear()
	g.slow.end()
	var p: Creature = g.field.partner
	if p == null or not p.move_ready(id):
		return
	if g.team.spend_gauge(int(TamerData.move(id).get("cost", 0))):
		p.cast(id, cursor())


## A move straight away (tests): pays its gauge cost first.
func use_move(i: int) -> bool:
	var p: Creature = g.field.partner
	if p == null or not p.alive():
		return false
	var id: String = String(p.rec.moves()[i])
	return p.move_ready(id) and g.team.spend_gauge(int(TamerData.move(id).get("cost", 0))) and p.cast(id, cursor())


func use_bond_move() -> bool:
	var p: Creature = g.field.partner
	if p == null or not p.rec.bond_move_ready():
		if p != null:
			g.hud.notice("Fight together to fill the bond meter first")
		return false
	var id: String = p.rec.bond_move()
	return p.move_ready(id) and g.team.spend_gauge(int(TamerData.move(id).get("cost", 0))) and p.cast(id, cursor())


func dodge() -> bool:
	if g.battle.on and g.field.partner != null:
		return g.field.partner.dodge(cursor(), TamerData.rule("control.dodge"))
	return g.trainer.roll(cursor())


func _physics_process(delta: float) -> void:
	_hover()
	_repath -= delta
	if _held and _repath <= 0.0 and not g.hud.panel_open():
		_repath = REPATH
		_move_to(cursor())
	if _rmb_held and g.battle.on and g.battle.brain() != null and g.battle.brain().target == null and g.field.partner != null:
		g.field.partner.cast(String(g.field.partner.rec.data()["basic"]), cursor())      # held: the combo keeps going


## The creature under the cursor (wild ones and the starters), measured to its body's middle.
func _hover() -> void:
	var c: Vector2 = cursor()
	hovered = null
	var best: float = INF
	for n: Node in get_tree().get_nodes_in_group("creatures"):
		var cr := n as Creature
		if cr.side == Combatant.SIDE_TEAM or cr.fainted_now:
			continue
		var d: float = c.distance_to(cr.global_position + Vector2(0, -cr.view.body_height() * 0.5))
		if d < cr.hit_radius() + PICK_PAD and d < best:
			best = d
			hovered = cr
	CreatureTag.hovered = hovered
