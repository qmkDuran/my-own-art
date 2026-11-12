class_name TamerInput
extends Node
## Mouse and keys to commands. In battle YOU are your creature: LMB moves it (hold to keep moving), RMB is its
## basic physical attack (at the creature under the cursor, or a swing toward the cursor; hold to keep the combo
## going), Space its dodge, Q W E R its moves (hold to see where it lands, release to use it; a status move is
## channelled while held), 1-3 swap, F the Sync Lens. Outside battle: LMB walks the trainer, Space rolls, F uses what
## you stand next to (the Gate Hall's lever, switch, station and lens stand), Z V items, C camp, I creature info,
## F1 (dev) a shiny. The pointer can be the real mouse or a test's virtual cursor.

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


## In battle with your creature under control?
func fighting() -> bool:
	return g.battle.on and brain() != null


func brain() -> ControlledBrain:
	var p: Creature = g.field.partner
	return p.brain as ControlledBrain if p != null and is_instance_valid(p) else null


func _unhandled_input(event: InputEvent) -> void:
	if g.hud.panel_open():
		if event.is_action_pressed("menu"):
			g.hud.close_panels()
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
	elif event.is_action_pressed("inventory"):
		g.hud.info_panel.toggle(g.team.current())
	elif event.is_action_pressed("item_berry"):
		g.field.use_item("berry")
	elif event.is_action_pressed("item_salts"):
		g.field.use_item("salts")
	elif event.is_action_pressed("dev_shiny"):
		g.dev_shiny()
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("camp") and g.camp.resting:
		g.hud.camp_panel.toggle()
	for i: int in TamerKeys.SWAPS.size():
		if event.is_action_pressed(TamerKeys.SWAPS[i]):
			g.field.swap(i)
	for i: int in TamerKeys.MOVE_SLOTS.size():
		if event.is_action_pressed(TamerKeys.MOVE_SLOTS[i]):
			press_move(i)
		elif event.is_action_released(TamerKeys.MOVE_SLOTS[i]):
			release_move(i)


## F: in the Gate Hall, whatever you stand next to; elsewhere the Sync Lens.
func interact() -> void:
	if g.area == "hall" and not g.battle.on:
		g.hall.use_nearby()
	else:
		g.lens.request()


## LMB pressed at the cursor: walk (the trainer outside battle, your creature in battle). It never attacks.
func press() -> void:
	_move_to(cursor())


func _move_to(p: Vector2) -> void:
	if fighting():
		brain().goal = p
		brain().target = null
	elif not g.battle.on:
		g.lens.cancel()
		g.trainer.walk_to(p)


## RMB in battle: your creature goes for the creature under the cursor, or swings its basic toward the cursor.
func attack() -> void:
	if not fighting():
		return
	var foe: Creature = hovered if hovered != null and hovered.side == Combatant.SIDE_WILD else null
	g.guide.done("battle")
	brain().goal = Vector2.INF
	brain().target = foe
	if foe != null:
		Fx.ring(g.fx_layer, foe.global_position, foe.hit_radius() * 2.5, foe.hit_radius() * 1.2, Pal.c("gold"), 0.25)
		Audio.sfx("ui_click", -10.0, 1.4)
	else:
		g.field.partner.cast(brain().basic_id(), cursor())


func _move_id(i: int) -> String:
	var ids: Array = g.field.partner.rec.moves()
	return String(ids[i]) if i < ids.size() else ""


## A move key goes down. A status move starts channelling; another shows its ghost at the cursor (time does not
## slow) if the gauge can pay for it.
func press_move(i: int) -> void:
	if not fighting() or not g.field.partner.alive():
		return
	var id: String = _move_id(i)
	if id == "":
		return
	var m: Dictionary = TamerData.move(id)
	if String(m["type"]) == "status":
		g.field.partner.begin_channel(id)
		return
	if g.team.gauge + 0.001 < float(m.get("cost", 0)):
		g.hud.gauge_short(int(m.get("cost", 0)))
		return
	g.aim.aim(g.field.partner, id)


## The key comes up: a channelled status move goes off with the strength held; another move is paid for and used
## at the cursor.
func release_move(i: int) -> void:
	var p: Creature = g.field.partner
	if p == null or not is_instance_valid(p):
		g.aim.clear()
		return
	var id: String = _move_id(i)
	if p.channel_id != "" and p.channel_id == id:
		if p.release_channel(cursor()):
			g.guide.done("status")
		return
	if not g.aim.aiming() or g.aim.move_id != id:
		return
	g.aim.clear()
	use(id)


## Uses move `id` at the cursor now, paying its gauge cost (tests call this directly for non-status moves).
func use(id: String) -> bool:
	var p: Creature = g.field.partner
	var cost: int = int(TamerData.move(id).get("cost", 0))
	if p == null or not p.move_ready(id) or g.team.gauge + 0.001 < float(cost):
		return false
	if not p.cast(id, cursor()):
		return false
	g.team.spend_gauge(cost)
	if String(TamerData.move(id)["type"]) == "special":
		g.guide.done("special")
	return true


func dodge() -> bool:
	if fighting():
		return g.field.partner.dodge(cursor(), TamerData.rule("control.dodge"))
	if g.battle.on:
		return false
	return g.trainer.roll(cursor())


func _physics_process(delta: float) -> void:
	_hover()
	_repath -= delta
	if _held and _repath <= 0.0 and not g.hud.panel_open():
		_repath = REPATH
		_move_to(cursor())
	if _rmb_held and fighting() and brain().target == null:
		g.field.partner.cast(brain().basic_id(), cursor())      # held: the combo keeps going


## The creature under the cursor (not your own), measured to its body's middle.
func _hover() -> void:
	var c: Vector2 = cursor()
	hovered = null
	var best: float = INF
	for n: Node in get_tree().get_nodes_in_group("creatures"):
		var cr := n as Creature
		if cr.side == Combatant.SIDE_TEAM or cr.fainted_now:
			continue
		var d: float = c.distance_to(cr.global_position + Vector2(0, -cr.view.body_height() * cr.size_k * 0.5))
		if d < cr.hit_radius() + PICK_PAD and d < best:
			best = d
			hovered = cr
	CreatureTag.hovered = hovered
