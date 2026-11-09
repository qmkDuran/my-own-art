class_name TrainerPortrait
extends Trainer
## The trainer as a small portrait frame beside the heart, like an RPG party frame.
##
## The face shows how the fight goes: it shouts each skill command (three ticks pop above its
## mouth side, and it bounces a pixel), cheers on a level up, looks worried at low health,
## smiles when out of combat and blinks now and then (TrainerPortraitMood). Trainer's Aid
## tonics fly from the portrait into the world.
##
## The face is one SpriteFrames with an animation per expression (neutral, calm, worried,
## shout, cheer, toss); an expression's second frame, if it has one, is its blink. A new
## trainer design only swaps that resource.

## The frame's side (the stone edge included, the dark outline around it not).
const SIDE := 22
## The face's top-left inside the frame, and its size (it fills the frame's inside).
const FACE_TOP_LEFT := Vector2(1, 1)
const FACE_SIZE := Vector2(20, 20)
## The backdrop behind the face (inside the frame's dark line): lighter above, darker below.
const BACKDROP := Rect2(2, 2, 18, 18)
const BACKDROP_SPLIT_ROW := 9
## Where the shout's ticks pop from: above the frame, over the face's mouth side.
const SHOUT_ANCHOR := Vector2i(15, -3)
## The face hops up a pixel for the first half of this when shouting.
const BOUNCE_SECONDS := 0.16
## Where the tonic leaves the portrait: its centre.
const TONIC_LAUNCH_OFFSET := Vector2(SIDE / 2.0, SIDE / 2.0)

## The trainer's face: one animation per expression.
@export var frames: SpriteFrames

var _mood := TrainerPortraitMood.new()
var _shout_ticks := PortraitShoutTicks.new()
var _bounce := HudMotion.new(BOUNCE_SECONDS)
var _health: Health

@onready var combat_state: CombatState = $CombatState


func _ready() -> void:
	super()
	var progression := get_node_or_null("/root/Progression")
	if progression != null and progression.has_signal("leveled_up"):
		progression.connect("leveled_up", func(_level: int) -> void: _mood.cheer())


func _process(delta: float) -> void:
	if not is_instance_valid(_health):
		_health = PlayerFinder.find_component(self, "Health") as Health
	_mood.advance(delta)
	_shout_ticks.advance(delta)
	_bounce.advance(delta)
	queue_redraw()


## A skill was used: the trainer shouts the command.
func shout() -> void:
	_mood.shout()
	_shout_ticks.start()
	_bounce.start()
	combat_state.note_fighting()


func toss_tonic(at: Node2D, on_land: Callable) -> void:
	_mood.toss()
	_bounce.start()
	super(at, on_land)


## The tonic starts at the portrait, turned into world coordinates.
func tonic_launch_point() -> Vector2:
	var screen_point := get_global_transform_with_canvas() * TONIC_LAUNCH_OFFSET
	return get_viewport().get_canvas_transform().affine_inverse() * screen_point


func _draw() -> void:
	PixelShape.draw_stone_frame(self, SIDE)
	draw_rect(BACKDROP, ApolloPalette.DARK)
	draw_rect(Rect2(BACKDROP.position, Vector2(BACKDROP.size.x, BACKDROP_SPLIT_ROW)), ApolloPalette.SLATE)
	var face := _face_texture()
	if face != null:
		_draw_face(face, int(-_bounce.bounce().y))
	_shout_ticks.draw(self, SHOUT_ANCHOR)


## The face, raised by `lift` pixels; the rows pushed above the frame's inside are cut off.
func _draw_face(face: Texture2D, lift: int) -> void:
	var shown := Vector2(FACE_SIZE.x, FACE_SIZE.y - lift)
	draw_texture_rect_region(face, Rect2(FACE_TOP_LEFT, shown), Rect2(Vector2(0, lift), shown))


func _face_texture() -> Texture2D:
	var expression := _mood.expression(_health_share(), combat_state.is_in_combat())
	if frames == null or not frames.has_animation(expression):
		return null
	var count := frames.get_frame_count(expression)
	if count == 0:
		return null
	var index := 1 if _mood.is_blinking() and count > 1 else 0
	return frames.get_frame_texture(expression, index)


func _health_share() -> float:
	if not is_instance_valid(_health) or _health.max_health <= 0:
		return 1.0
	return float(_health.current_health) / float(_health.max_health)
