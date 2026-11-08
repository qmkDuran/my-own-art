class_name HudTrainer
extends Trainer
## The trainer standing in the skill bar, between W and E, with a thin gold outline.
##
## In combat he shows his back (watching the fight with you); after a few calm seconds he turns
## to face you, with a quick two-frame turn, and he turns back the moment a fight starts.
## He bobs a little while Emberoo walks, shouts (three ticks popping from his head) when a skill
## is used, and Trainer's Aid tonics fly from him into the world.
##
## His look is one SpriteFrames with a "back" and a "front" animation, so a new trainer design
## only swaps that resource. The outline and the turn frames are made from the art at runtime.

## How long each step of the shout lasts (the skill slot's flash keeps the same beat).
const SHOUT_STAGE_SECONDS := 0.0875
## The shout's three ticks, as [start relative to the head's top centre, direction]:
## up-left, straight up, up-right. They start just outside the gold outline of the
## 6-pixel-wide head (12×18 stand-in art).
const SHOUT_TICKS := [
	[Vector2i(-6, 0), Vector2i(-1, -1)],
	[Vector2i(0, -4), Vector2i(0, -1)],
	[Vector2i(5, 0), Vector2i(1, -1)],
]
## Each step of the shout: how far out the ticks start, how long they are, and their colour.
const SHOUT_STAGES := [
	{"distance": 0, "length": 2, "color": ApolloPalette.WHITE},
	{"distance": 1, "length": 3, "color": ApolloPalette.WHITE},
	{"distance": 3, "length": 2, "color": ApolloPalette.GOLD},
	{"distance": 5, "length": 1, "color": ApolloPalette.ORANGE_DARK},
]
## Seconds each of the two turn frames shows.
const TURN_FRAME_SECONDS := 0.07
## While Emberoo walks, the trainer moves up or down one pixel this often.
const BOB_STEP_SECONDS := 0.15
## Emberoo counts as walking above this speed, in pixels per second.
const WALKING_SPEED := 5.0
## Where the tonic leaves the trainer's hands, from his feet (the hands' row of the 12×18 art).
const HANDS_OFFSET := Vector2(0, -6)

## The trainer's look: a "back" and a "front" animation (one frame each is enough;
## more frames play while Emberoo walks).
@export var frames: SpriteFrames
@export var back_animation: StringName = &"back"
@export var front_animation: StringName = &"front"

## Outlined pictures already made, per texture: {texture: {is_squashed: HudTrainerPicture}}.
static var _picture_cache: Dictionary = {}

var _is_facing_back: bool = false
## Seconds into the turn, or -1 when not turning.
var _turn_time: float = -1.0
## Seconds into the shout, or -1 when not shouting.
var _shout_time: float = -1.0
var _walk_time: float = 0.0
var _player: Node2D

@onready var combat_state: CombatState = $CombatState


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = PlayerFinder.find(self)
	_update_facing(delta)
	_update_walk(delta)
	if _shout_time >= 0.0:
		_shout_time += delta
		if _shout_stage() >= SHOUT_STAGES.size():
			_shout_time = -1.0
	queue_redraw()


## A skill was used: three ticks pop from the trainer's head.
func shout() -> void:
	_shout_time = 0.0
	combat_state.note_fighting()


## The tonic starts at the HUD trainer's hands, turned into world coordinates.
func tonic_launch_point() -> Vector2:
	var screen_point := get_global_transform_with_canvas() * HANDS_OFFSET
	return get_viewport().get_canvas_transform().affine_inverse() * screen_point


func _draw() -> void:
	var picture := _current_picture()
	if picture == null:
		return
	var origin := picture.offset + Vector2(0, -1 if _is_bobbing_up() else 0)
	picture.draw(self, origin)
	if _shout_time >= 0.0:
		_draw_shout(Vector2i(0, int(origin.y) + picture.top_row))


# --- Facing -------------------------------------------------------------------

## Back in combat, front when calm. A turn starts at once; if the reason for it ends
## mid-turn, he just stays as he was.
func _update_facing(delta: float) -> void:
	var wants_back := combat_state.is_in_combat()
	if _is_turning():
		if wants_back == _is_facing_back:
			_turn_time = -1.0
			return
		_turn_time += delta
		if _turn_time >= TURN_FRAME_SECONDS * 2.0:
			_is_facing_back = wants_back
			_turn_time = -1.0
	elif wants_back != _is_facing_back:
		_turn_time = 0.0


func _is_turning() -> bool:
	return _turn_time >= 0.0


## Mid-turn: first the old view squashed to half width, then the new one; otherwise the full view.
func _current_picture() -> HudTrainerPicture:
	if not _is_turning():
		return _picture_for(_is_facing_back, false)
	var is_second_frame := _turn_time >= TURN_FRAME_SECONDS
	return _picture_for(_is_facing_back != is_second_frame, true)


func _picture_for(back_view: bool, is_squashed: bool) -> HudTrainerPicture:
	var texture := _view_texture(back_animation if back_view else front_animation)
	if texture == null:
		return null
	var by_squash: Dictionary = _picture_cache.get_or_add(texture, {})
	if not by_squash.has(is_squashed):
		by_squash[is_squashed] = HudTrainerPicture.from_texture(texture, is_squashed)
	return by_squash[is_squashed]


## The animation's frame: the first one standing still, cycling while Emberoo walks.
func _view_texture(animation: StringName) -> Texture2D:
	if frames == null or not frames.has_animation(animation):
		return null
	var count := frames.get_frame_count(animation)
	if count == 0:
		return null
	var index := 0
	if _is_player_walking():
		index = int(_walk_time * frames.get_animation_speed(animation)) % count
	return frames.get_frame_texture(animation, index)


# --- Walk bob -----------------------------------------------------------------

func _update_walk(delta: float) -> void:
	_walk_time = _walk_time + delta if _is_player_walking() else 0.0


func _is_player_walking() -> bool:
	if not is_instance_valid(_player):
		return false
	var velocity: Variant = _player.get("velocity")
	return velocity is Vector2 and (velocity as Vector2).length() > WALKING_SPEED


## Up on every other step while walking.
func _is_bobbing_up() -> bool:
	return _walk_time > 0.0 and int(_walk_time / BOB_STEP_SECONDS) % 2 == 1


# --- Shout --------------------------------------------------------------------

func _shout_stage() -> int:
	return int(_shout_time / SHOUT_STAGE_SECONDS)


## The ticks fly outward from the head over the shout's steps, white, then gold, then orange.
func _draw_shout(head_top_centre: Vector2i) -> void:
	var stage: int = _shout_stage()
	if stage >= SHOUT_STAGES.size():
		return
	var step: Dictionary = SHOUT_STAGES[stage]
	for tick: Array in SHOUT_TICKS:
		var start: Vector2i = head_top_centre + (tick[0] as Vector2i)
		var direction: Vector2i = tick[1]
		for distance in range(step["distance"], step["distance"] + step["length"]):
			PixelShape.draw_pixel(self, Vector2(start + direction * distance), step["color"])
