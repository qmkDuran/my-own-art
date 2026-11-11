class_name TamerInput
extends Node
## Mouse and keys to commands. LMB: on a starter, pick it; on a wild creature, point your creature at it; else walk
## (hold to keep walking). While you hold Shift the same clicks steer your creature instead. Q W E R: the active
## creature's moves at the cursor; T: its bond move. Space: roll (or the creature's dodge while steering). 1-3 swap,
## 4-5 items, F (held) befriend, C camp. The pointer can be the real mouse or a test's virtual cursor.

const REPATH: float = 0.12
const PICK_PAD: float = 14.0

var g: TamerGame
var cursor_override: Vector2 = Vector2.INF
var hovered: Creature
var _held: bool = false
var _repath: float = 0.0


func setup(game: TamerGame) -> void:
	g = game


func cursor() -> Vector2:
	return cursor_override if cursor_override != Vector2.INF else g.get_global_mouse_position()


func _unhandled_input(event: InputEvent) -> void:
	if g.hud.camp_panel.visible and event.is_action_pressed("menu"):
		g.hud.camp_panel.close()
		return
	if event.is_action_pressed("control"):
		g.control.take()
	elif event.is_action_released("control"):
		g.control.release()
	elif event.is_action_pressed("click"):
		_held = true
		press()
	elif event.is_action_released("click"):
		_held = false
	else:
		_keys(event)


func _keys(event: InputEvent) -> void:
	if event.is_action_pressed("dash"):
		dodge()
	elif event.is_action_pressed("bond_move"):
		use_bond_move()
	elif event.is_action_pressed("item_berry"):
		g.field.use_item("berry")
	elif event.is_action_pressed("item_salts"):
		g.field.use_item("salts")
	elif event.is_action_pressed("camp") and g.camp.resting:
		g.hud.camp_panel.toggle()
	for i: int in TamerKeys.SWAPS.size():
		if event.is_action_pressed(TamerKeys.SWAPS[i]) and g.field.swap(i):
			g.guide.done("swap")
	for i: int in TamerKeys.MOVE_SLOTS.size():
		if event.is_action_pressed(TamerKeys.MOVE_SLOTS[i]):
			use_move(i)


## LMB pressed at the cursor.
func press() -> void:
	if g.meeting != null and hovered != null and hovered.side == StarterMeeting.SIDE:
		g.meeting.pick(hovered)
		return
	var foe: Creature = hovered if hovered != null and hovered.side == Combatant.SIDE_WILD else null
	if g.control.on:
		var b: ControlledBrain = g.control.brain()
		b.target = foe
		b.goal = Vector2.INF if foe != null else cursor()
		return
	if foe != null:
		g.trainer.attack_target = foe
		_mark(foe)
	else:
		g.trainer.walk_to(cursor())


func _mark(foe: Creature) -> void:
	Fx.ring(g.fx_layer, foe.global_position, foe.hit_radius() * 2.5, foe.hit_radius() * 1.2, Pal.c("gold"), 0.25)
	Audio.sfx("ui_click", -10.0, 1.4)


func use_move(i: int) -> bool:
	var p: Creature = g.field.partner
	if p == null or not p.alive():
		return false
	return p.cast(String(p.rec.moves()[i]), cursor())


func use_bond_move() -> bool:
	var p: Creature = g.field.partner
	if p == null or not p.rec.bond_move_ready():
		if p != null:
			g.hud.notice("Fight together to fill the bond meter first")
		return false
	return p.cast(p.rec.bond_move(), cursor())


func dodge() -> bool:
	if g.control.on and g.field.partner != null:
		return g.field.partner.dodge(cursor(), TamerData.rule("control.dodge"))
	return g.trainer.roll(cursor())


func _physics_process(delta: float) -> void:
	_hover()
	_repath -= delta
	if _held and _repath <= 0.0 and not g.control.on and hovered == null and not g.hud.camp_panel.visible:
		_repath = REPATH
		g.trainer.walk_to(cursor())


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
