class_name SpriteSheetLoader
extends RefCounted
## Turns sprite-sheet PNGs into animations Godot can play.
##
## Sheet files must be named "<creature>_<view>_<action>_sheet.png",
## for example "emberoo_side_idle_sheet.png", with frames laid out left to right.
## Missing sheets are skipped, so animations can be added one at a time.


static func build_sprite_frames(
		sheet_folder: String,
		creature_name: String,
		view_names: Array,
		animation_settings: Dictionary,
		frame_size: Vector2i
) -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")

	for action: String in animation_settings:
		for view: String in view_names:
			var sheet_path := "%s/%s_%s_%s_sheet.png" % [sheet_folder, creature_name, view, action]
			if not ResourceLoader.exists(sheet_path):
				continue
			var animation_name := animation_name_for(action, view)
			_add_animation(sprite_frames, animation_name, load(sheet_path), animation_settings[action], frame_size)

	return sprite_frames


static func animation_name_for(action: String, view: String) -> String:
	return "%s_%s" % [action, view]


static func _add_animation(
		sprite_frames: SpriteFrames,
		animation_name: String,
		sheet: Texture2D,
		settings: Dictionary,
		frame_size: Vector2i
) -> void:
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_speed(animation_name, settings["frames_per_second"])
	sprite_frames.set_animation_loop(animation_name, settings["loops"])
	for frame in _cut_into_frames(sheet, frame_size):
		sprite_frames.add_frame(animation_name, frame)


static func _cut_into_frames(sheet: Texture2D, frame_size: Vector2i) -> Array[AtlasTexture]:
	var frames: Array[AtlasTexture] = []
	@warning_ignore("integer_division")
	var frame_count := sheet.get_width() / frame_size.x

	for frame_index in frame_count:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(frame_index * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.append(frame)

	return frames
