class_name Npc
extends CharacterBody2D
## One of the great multitude of the redeemed (Rev 7:9): white robes, some with palms.
## Modes: "stand" (breathing idle), "palm" (sways a palm branch), "walk" (calm loop along a path).
## Standing people have four facings (down/up/left; right = mirrored left) and turn toward the player when spoken to.
## Each carries one or more Scripture quotations (NIV, from data/verses.json), spoken in turn when the player talks to them.

const SPEED: float = 34.0
const FRAME: int = 64
const FEET_Y: int = 61
const STRIDE: float = 22.0
const FADE: float = 0.8
const HEAR_DISTANCE: float = 260.0
const ROWS: Dictionary = {"down": 0, "up": 1, "left": 2, "right": 2}
const COLUMNS: int = 4
const COL_IDLE: int = 0
const COL_BREATHE: int = 1
const COL_PALM_A: int = 2
const COL_PALM_B: int = 3

var quotes: Array[String] = []
var _next_quote: int = 0
var mode: String = "stand"
var path: Array[Vector2] = []
## Footstep sound prefix for walkers (e.g. "step_gold" -> step_gold0..2), empty for silent.
var step_sound: String = ""
## Walk the path once, fade away at its end and begin again at its start (a procession), instead of looping.
var one_way: bool = false

var _sheet_path: String = ""
var _home_facing: String = "down"
var _facing: String = "down"
var _sprite: Sprite2D
var _anim: AnimatedSprite2D
var _bubble: Sprite2D
var _phase: float = 0.0
var _time: float = 0.0
var _target: int = 0
var _wait: float = 0.0
var _step_acc: float = 0.0
var _turned_until: float = -1.0


## A standing / palm-swaying person with a 4-direction sheet: art/people/pNN.png (person number) or art/people/<name>.png.
static func standing(person: Variant, at: Vector2, how: String, facing: String, verse: String) -> Npc:
	var n := Npc.new()
	n._sheet_path = "res://art/people/%s.png" % (person if person is String else "p%02d" % int(person))
	n.mode = how
	n._home_facing = facing
	n._facing = facing
	n.position = at
	n.quotes.append(verse)
	return n


## A person who walks a calm loop (sheet in the hero.png layout).
static func walker(sheet_path: String, loop: Array[Vector2], verse: String, steps: String = "",
		procession: bool = false, start: Vector2 = Vector2.INF) -> Npc:
	var n := Npc.new()
	n.mode = "walk"
	n.path = loop
	n.one_way = procession
	n.position = loop[0] if start == Vector2.INF else start
	n._target = 0 if start == Vector2.INF else 1
	n.quotes.append(verse)
	n.step_sound = steps
	n._sheet_path = sheet_path
	return n


func _ready() -> void:
	_phase = randf_range(0.0, 3.0)
	_add_feet_collider()
	if mode == "walk":
		_add_walker_sprite()
	else:
		_add_sheet_sprite()
	_add_bubble()


func _add_feet_collider() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 6)
	shape.shape = rect
	shape.position = Vector2(0, -2)
	add_child(shape)


func _add_walker_sprite() -> void:
	_anim = AnimatedSprite2D.new()
	_anim.sprite_frames = Player.build_frames(load(_sheet_path) as Texture2D)
	_anim.centered = false
	_anim.offset = Vector2(-FRAME / 2.0, -FEET_Y)
	add_child(_anim)
	_anim.play("idle_down")


func _add_sheet_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = load(_sheet_path) as Texture2D
	_sprite.hframes = COLUMNS
	_sprite.vframes = 3
	_sprite.centered = false
	_sprite.offset = Vector2(-FRAME / 2.0, -FEET_Y)
	add_child(_sprite)


func _add_bubble() -> void:
	_bubble = Sprite2D.new()
	_bubble.texture = load("res://art/people/bubble.png")
	_bubble.position = Vector2(10, -66)
	_bubble.visible = false
	add_child(_bubble)


## The verse to say now; several verses are said in turn on repeated talks.
func take_quote() -> String:
	var q: String = quotes[_next_quote % quotes.size()]
	_next_quote += 1
	return q


## Turn toward `who` (as far as four facings allow) and show the speech bubble for a while.
func speak(who: Vector2, seconds: float = 5.5) -> void:
	var d: Vector2 = who - global_position
	var facing: String = ("right" if d.x > 0.0 else "left") if absf(d.x) > absf(d.y) else ("down" if d.y > 0.0 else "up")
	if mode == "walk":
		_wait = seconds
		_facing = "side" if facing in ["left", "right"] else facing
		_anim.flip_h = facing == "right"
		_anim.play("idle_" + _facing)
	else:
		_facing = facing
		_turned_until = _time + seconds
	_bubble.visible = true
	get_tree().create_timer(seconds).timeout.connect(func() -> void: _bubble.visible = false)


func _physics_process(delta: float) -> void:
	_time += delta
	if mode == "walk":
		_walk(delta)
		return
	if _turned_until >= 0.0 and _time > _turned_until:
		_turned_until = -1.0
		_facing = _home_facing
	_sprite.flip_h = _facing == "right"
	_sprite.frame = ROWS[_facing] * COLUMNS + _column()


func _column() -> int:
	match mode:
		"palm":
			var beat: int = int(_time * 1.2 + _phase) % 4   # idle, lean one way, idle, lean the other way
			return [COL_IDLE, COL_PALM_A, COL_IDLE, COL_PALM_B][beat]
		_:
			return COL_BREATHE if int(_time * 0.9 + _phase) % 3 == 2 else COL_IDLE


func _walk(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0 or _anim.animation.begins_with("walk"):
			_set_anim(Vector2.ZERO)
		return
	var to: Vector2 = path[_target] - global_position
	if to.length() < 2.0:
		if one_way and _target == path.size() - 1:
			_begin_again()
			return
		_target = (_target + 1) % path.size()
		_wait = randf_range(1.0, 2.5)          # a calm pause at each turn
		return
	var dir: Vector2 = to.normalized()
	velocity = dir * SPEED
	var before: Vector2 = global_position
	move_and_slide()
	var moved: float = global_position.distance_to(before)
	if moved < SPEED * delta * 0.3:
		_wait = 0.8                              # someone is in the way: wait politely
		dir = Vector2.ZERO
	_footsteps(moved)
	_set_anim(dir)



## End of a procession: fade into the light, reappear at the start and fade in.
func _begin_again() -> void:
	_wait = FADE * 2.0 + 0.2
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, FADE)
	tw.tween_callback(func() -> void:
		position = path[0]
		_target = 1)
	tw.tween_property(self, "modulate:a", 1.0, FADE)


func _footsteps(moved: float) -> void:
	if step_sound == "":
		return
	_step_acc += moved
	if _step_acc < STRIDE:
		return
	_step_acc = 0.0
	var listener: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if listener == null:
		return
	var d: float = listener.global_position.distance_to(global_position)
	if d < HEAR_DISTANCE:
		var variants: int = 3 if step_sound == "step_gold" else 2
		Audio.sfx("%s%d" % [step_sound, randi_range(0, variants - 1)], lerpf(-26.0, -40.0, d / HEAR_DISTANCE), randf_range(0.95, 1.05))


func _set_anim(dir: Vector2) -> void:
	if dir.length() > 0.1:
		_facing = "side" if absf(dir.x) >= absf(dir.y) * 0.9 else ("down" if dir.y > 0.0 else "up")
		_anim.flip_h = _facing == "side" and dir.x > 0.0
	var anim: String = ("walk_" if dir.length() > 0.1 else "idle_") + _facing
	if _anim.animation != anim:
		_anim.play(anim)
