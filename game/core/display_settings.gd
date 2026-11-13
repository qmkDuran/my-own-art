class_name DisplaySettings
extends Node
## Display settings that keep the GPU cool and the picture right: a frame-rate cap (default 60; F cycles 30, 60,
## 120 and uncapped), VSync (on by default; V toggles), fullscreen at the display's own resolution (F11), and the
## graphics tier, all saved to user://settings.json so they stick between sessions.

signal changed(text: String)

const SAVE_PATH: String = "user://settings.json"
const TEST_PATH: String = "user://test_settings.json"
const UNCAPPED: int = 0

var frame_cap: int = 0
var vsync: bool = true
var fullscreen: bool = true
var tier: String = ""
var save_path: String = SAVE_PATH


func setup() -> void:
	name = "DisplaySettings"
	var spec: Dictionary = Tuning.doc("graphics")["display"]
	frame_cap = int(spec["default_frame_cap"])
	vsync = spec["vsync"]
	fullscreen = spec["fullscreen"]
	tier = Tuning.doc("graphics")["default"]
	if not TestRunner.is_playing():
		save_path = TEST_PATH
	_load()
	apply()


func apply() -> void:
	Engine.max_fps = frame_cap
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else
			DisplayServer.WINDOW_MODE_WINDOWED)


func cycle_frame_cap() -> void:
	var caps: Array = Tuning.doc("graphics")["display"]["frame_caps"]
	frame_cap = int(caps[(caps.find(frame_cap) + 1) % caps.size()])
	_changed("Frame cap: " + ("uncapped" if frame_cap == UNCAPPED else str(frame_cap) + " fps"))


func toggle_vsync() -> void:
	vsync = not vsync
	_changed("VSync " + ("on" if vsync else "off"))


func toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	_changed("Fullscreen" if fullscreen else "Windowed")


## Remembers the graphics tier chosen elsewhere (so it is saved with the rest).
func remember_tier(new_tier: String) -> void:
	tier = new_tier
	save()


func save() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({ "frame_cap": frame_cap, "vsync": vsync, "fullscreen": fullscreen,
			"tier": tier }))


func _changed(text: String) -> void:
	apply()
	save()
	changed.emit(text)


func _load() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not saved is Dictionary:
		return
	frame_cap = int(saved.get("frame_cap", frame_cap))
	vsync = bool(saved.get("vsync", vsync))
	fullscreen = bool(saved.get("fullscreen", fullscreen))
	tier = String(saved.get("tier", tier))
