class_name GameInput
extends Node
## Mouse + keyboard to commands. LMB: on an item name take it, on an enemy attack it (walking into reach first),
## on a usable thing use it, else walk (hold to keep walking toward the cursor). Shift: stand still and use the
## LMB skill toward the cursor. RMB/Q/W/E/R: skills. Space: Wickstep. 1: tonic. Panels and Alt labels.
## The pointer can be the real mouse or a virtual cursor (the demo bot), through the same methods.

const REPATH: float = 0.12
const ENEMY_PICK: float = 18.0
const FIGHT_RANGE: float = 260.0      ## an awake enemy this close: names of usable things stay hidden
const HOLD_SLOT: String = "lmb"
const ATTACK_REACH: float = 0.7      ## held attack on an enemy: walk until it is this share of the bolt's range away

var g: Game
var cursor_override: Vector2 = Vector2.INF
var lmb_held: bool = false
var hovered_enemy: Enemy
var hovered_item: GroundItem
var hovered_use: Interactable
var _attack: Enemy
var _take: GroundItem
var _use: Interactable
var _repath: float = 0.0


func setup(game: Game) -> void:
	g = game


func cursor() -> Vector2:
	return cursor_override if cursor_override != Vector2.INF else g.get_global_mouse_position()


func standing() -> bool:
	return Input.is_action_pressed("stand")


# ------------------------------------------------------------------ events
func _unhandled_input(event: InputEvent) -> void:
	if g.ui.handle_global(event):
		return
	if get_tree().paused or g.ui.blocking():
		return
	if event.is_action_pressed("click"):
		press()
	elif event.is_action_released("click"):
		lmb_held = false
	elif event.is_action_pressed("dash"):
		g.player.dash(cursor())
	elif event.is_action_pressed("tonic"):
		g.player.drink_tonic()
	else:
		for k: String in ["rmb", "q", "w", "e", "r"]:
			if event.is_action_pressed("slot_" + k):
				use_slot(k)


func use_slot(key: String) -> bool:
	var s: String = String(g.player.prog.slots.get(key, ""))
	return s != "" and g.player.skills.try_use(s, cursor())


## LMB pressed at the cursor.
func press() -> void:
	lmb_held = true
	_clear_targets()
	if standing():
		use_slot(HOLD_SLOT)
		return
	if hovered_item != null:
		_take = hovered_item
	elif hovered_enemy != null:
		_attack = hovered_enemy
	elif hovered_use != null:
		_use = hovered_use
	else:
		g.player.walk_to(cursor())


func _clear_targets() -> void:
	_attack = null
	_take = null
	_use = null


# ------------------------------------------------------------------ frame
func _physics_process(delta: float) -> void:
	_hover()
	_repath -= delta
	if g.player.dead:
		return
	if lmb_held and standing():
		use_slot(HOLD_SLOT)
	elif _attack != null:
		_pursue_attack()
	elif _take != null:
		_pursue_take()
	elif _use != null:
		_pursue_use()
	elif lmb_held and _repath <= 0.0 and not g.ui.blocking():
		_repath = REPATH
		var over: Enemy = hovered_enemy
		if over != null:
			_attack = over
		else:
			g.player.walk_to(cursor())


func _pursue_attack() -> void:
	if not is_instance_valid(_attack) or _attack.dead:
		_attack = null
		return
	var s: String = String(g.player.prog.slots.get(HOLD_SLOT, "wickbolt"))
	var reach: float = (g.player.skills.skill(s) as Wickbolt).reach() * ATTACK_REACH if s == "wickbolt" else 120.0
	if g.player.global_position.distance_to(_attack.global_position) <= reach + _attack.radius:
		g.player.stop()
		g.player.skills.try_use(s, _attack.global_position + Vector2(0, -10))
		if not lmb_held:
			_attack = null
	elif _repath <= 0.0:
		_repath = REPATH
		g.player.walk_to(_attack.global_position)


func _pursue_take() -> void:
	if not is_instance_valid(_take):
		_take = null
		return
	if g.player.global_position.distance_to(_take.global_position) < Interactable.REACH:
		if g.player.inv.add(_take.item):
			Audio.sfx("pickup", -6.0)
			_take.queue_free()
		else:
			g.hud.notice("Your bag is full")
		_take = null
	elif not g.player.walking():
		g.player.walk_to(_take.global_position)


func _pursue_use() -> void:
	if not is_instance_valid(_use):
		_use = null
		return
	if g.player.global_position.distance_to(_use.global_position) < Interactable.REACH + 14.0:
		g.player.stop()
		g.player.face(_use.global_position)
		_use.use(g)
		_use = null
	elif not g.player.walking():
		g.player.walk_to(_use.stand_point())


## What is under the cursor: item names first (they float above), then enemies, then usable things.
func _hover() -> void:
	var c: Vector2 = cursor()
	hovered_item = null
	if LabelStack.shown:
		for n: Node in get_tree().get_nodes_in_group("ground_items"):
			if (n as GroundItem).label_rect().has_point(c):
				hovered_item = n
	hovered_enemy = null
	var best: float = INF
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		var d: float = c.distance_to(e.global_position + Vector2(0, -e.body_height() * 0.5))
		if d < e.radius + ENEMY_PICK and d < best:
			best = d
			hovered_enemy = e
	var prev: Interactable = hovered_use
	hovered_use = null
	if hovered_enemy == null and hovered_item == null and not g.ui.blocking():
		for n: Node in get_tree().get_nodes_in_group("interactables"):
			if (n as Interactable).pick_rect().has_point(c) and (n as Interactable).title != "":
				hovered_use = n
	if prev != hovered_use and is_instance_valid(prev):
		prev.set_hover(false)
	if hovered_use != null:
		hovered_use.set_hover(true, not _fighting())


func _fighting() -> bool:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.awake and not e.dead and e.global_position.distance_to(g.player.global_position) < FIGHT_RANGE:
			return true
	return false
