class_name SpriteSheetLoader
extends RefCounted
## Turns sprite-sheet PNGs into animations Godot can play.
##
## Creature sheets must be named "<creature>_<view>_<action>_sheet.png",
## for example "emberoo_side_idle_sheet.png", with frames laid out left to right.
## Missing sheets are skipped, so animations can be added one at a time.
##
## Frame timings are given in seconds per frame, so each frame can have its own length
## (fast wind-ups, lingering follow-throughs). An action's settings may name another
## action's sheet as "sheet", to reuse its frames with different timings, or a
## "stand_in_sheet" used only for views where its own sheet isn't drawn.


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
		var settings: Dictionary = animation_settings[action]
		for view: String in view_names:
			var sheet_path := _sheet_path_for(sheet_folder, creature_name, view, action, settings)
			if sheet_path == "":
				continue
			add_animation(
				sprite_frames,
				animation_name_for(action, view),
				load(sheet_path),
				settings["frame_durations"],
				settings["loops"],
				frame_size
			)

	return sprite_frames


## The sheet an action uses in one view: its own (or the one it borrows as "sheet"), else
## its "stand_in_sheet", else "" when neither is drawn.
static func _sheet_path_for(sheet_folder: String, creature_name: String, view: String, action: String, settings: Dictionary) -> String:
	for sheet_action: String in [settings.get("sheet", action), settings.get("stand_in_sheet", "")]:
		var sheet_path := "%s/%s_%s_%s_sheet.png" % [sheet_folder, creature_name, view, sheet_action]
		if sheet_action != "" and ResourceLoader.exists(sheet_path):
			return sheet_path
	return ""


static func animation_name_for(action: String, view: String) -> String:
	return "%s_%s" % [action, view]


static func add_animation(
		sprite_frames: SpriteFrames,
		animation_name: String,
		sheet: Texture2D,
		frame_durations: Array,
		loops: bool,
		frame_size: Vector2i
) -> void:
	sprite_frames.add_animation(animation_name)
	# At 1 frame per second, each frame's duration multiplier equals its length in seconds.
	sprite_frames.set_animation_speed(animation_name, 1.0)
	sprite_frames.set_animation_loop(animation_name, loops)

	var frames := _cut_into_frames(sheet, frame_size)
	for frame_index in frames.size():
		var seconds := _duration_of_frame(frame_durations, frame_index)
		sprite_frames.add_frame(animation_name, frames[frame_index], seconds)


## Uses the matching duration, or repeats the last one if the sheet has more frames than timings.
static func _duration_of_frame(frame_durations: Array, frame_index: int) -> float:
	return frame_durations[mini(frame_index, frame_durations.size() - 1)]


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
