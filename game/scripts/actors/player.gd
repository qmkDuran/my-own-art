class_name Player
extends CharacterBody2D
## The glorified man. 8-way movement (walk, or run while "run" is held), 4-direction animation (right = mirrored left).

## Emitted every stride while walking (the scene picks the footstep sound for the surface).
signal stepped(at: Vector2)

const SPEED: float = 78.0
const RUN_FACTOR: float = 1.8
const RUN_ANIM_SCALE: float = 1.6
const STRIDE: float = 22.0
const FRAME: int = 64
const FEET_Y: int = 61  # feet row inside the 64x64 frame
const ROWS: Array = [["idle_down", 4, 2.0], ["idle_up", 4, 2.0], ["idle_side", 4, 2.0],
	["walk_down", 8, 10.0], ["walk_up", 8, 10.0], ["walk_side", 8, 10.0]]

## Scripted walks: the player walks to each (x, y) and then waits z seconds, instead of reading input.
var autopilot: Array[Vector3] = []
var autopilot_pause: float = 0.0
var frozen: bool = false

var _step_acc: float = 0.0
var _facing: String = "down"
var _flip: bool = false
var _sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = Player.build_frames(load("res://art/hero.png") as Texture2D)
	_sprite.centered = false
	_sprite.offset = Vector2(-FRAME / 2.0, -FEET_Y)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 6)
	shape.shape = rect
	shape.position = Vector2(0, -2)
	add_child(shape)
	_sprite.play("idle_down")


## Builds the animations from a hero.png-style sheet: rows idle down/up/side (4 frames), walk down/up/side (8 frames).
## Also used by the walking people.
static func build_frames(sheet: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for r: int in ROWS.size():
		var anim_name: String = ROWS[r][0]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, ROWS[r][2])
		frames.set_animation_loop(anim_name, true)
		for i: int in int(ROWS[r][1]):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(i * FRAME, r * FRAME, FRAME, FRAME)
			frames.add_frame(anim_name, atlas)
	return frames


## Turn to "down", "up", "side" (left) or "right" (side, mirrored).
func face(dir: String) -> void:
	_facing = "side" if dir == "right" else dir
	_flip = dir == "right"
	_sprite.flip_h = _flip
	_sprite.play("idle_" + _facing)


func is_running() -> bool:
	return autopilot.is_empty() and not frozen and Input.is_action_pressed("run")


func _input_vector() -> Vector2:
	if frozen:
		return Vector2.ZERO
	if not autopilot.is_empty():
		if autopilot_pause > 0.0:
			return Vector2.ZERO
		var target: Vector3 = autopilot[0]
		var to: Vector2 = Vector2(target.x, target.y) - global_position
		if to.length() < 2.0:
			autopilot.pop_front()
			autopilot_pause = target.z
			return Vector2.ZERO
		return to.normalized()
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _physics_process(delta: float) -> void:
	autopilot_pause = maxf(0.0, autopilot_pause - delta)
	var dir: Vector2 = _input_vector()
	var running: bool = is_running()
	velocity = dir * SPEED * (RUN_FACTOR if running else 1.0)
	var before: Vector2 = global_position
	move_and_slide()
	_step_acc += global_position.distance_to(before)   # running covers a stride sooner: faster footsteps
	if _step_acc >= STRIDE:
		_step_acc = 0.0
		stepped.emit(global_position)
	_sprite.speed_scale = RUN_ANIM_SCALE if running else 1.0
	_animate(dir)


func _animate(dir: Vector2) -> void:
	if dir.length() > 0.1:
		if absf(dir.x) >= absf(dir.y) * 0.9:
			_facing = "side"
			_flip = dir.x > 0.0
		else:
			_facing = "down" if dir.y > 0.0 else "up"
	var anim: String = ("walk_" if dir.length() > 0.1 else "idle_") + _facing
	_sprite.flip_h = _flip and _facing == "side"
	if _sprite.animation != anim:
		_sprite.play(anim)
