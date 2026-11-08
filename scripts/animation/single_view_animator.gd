class_name SingleViewAnimator
extends AnimatedSprite2D
## Animations for creatures drawn from one view only, like the toad that always faces the camera.
##
## Sheets are named "<prefix>_<action>_sheet.png", e.g. "toad_hop_sheet.png".

@export_dir var sheet_folder: String
@export var sheet_prefix: String
## Size of one frame in the sheets, e.g. 16×16 for creatures, 18×24 for humans.
@export var frame_size: Vector2i = Vector2i(16, 16)
## For each action: { "frame_durations": [seconds per frame], "loops": bool }.
@export var animation_settings: Dictionary = {}

## Where the sprite sits when the creature is on the ground.
var _ground_offset: Vector2


func _ready() -> void:
	_ground_offset = position
	sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation("default")

	for action: String in animation_settings:
		var sheet_path := "%s/%s_%s_sheet.png" % [sheet_folder, sheet_prefix, action]
		if not ResourceLoader.exists(sheet_path):
			continue
		var settings: Dictionary = animation_settings[action]
		SpriteSheetLoader.add_animation(
			sprite_frames, action, load(sheet_path), settings["frame_durations"], settings["loops"], frame_size
		)


func show_animation(action: String) -> void:
	if animation != action and sprite_frames.has_animation(action):
		play(action)


## Always starts from the first frame, e.g. for a new hop or attack.
## If the action isn't drawn yet, the stand-in is played instead (when given).
func replay_animation(action: String, stand_in: String = "") -> void:
	if not sprite_frames.has_animation(action):
		action = stand_in
	if not sprite_frames.has_animation(action):
		return
	play(action)
	frame = 0
	frame_progress = 0.0


## Raises the sprite off the ground, in pixels. The shadow stays put, which sells the jump.
func lift(height: float) -> void:
	position = _ground_offset + Vector2(0, -roundf(height))
