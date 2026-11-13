class_name DisplaySettings
extends Node
## Display settings that keep the GPU cool and the picture right: a frame-rate cap (default 60; F cycles 30, 60,
## 120 and uncapped), VSync (on by default; F9 toggles), fullscreen at the display's own resolution (F11), and the
## graphics tier, all saved to user://settings.json so they stick between sessions. F10 switches the Windows
## rendering driver between Vulkan (the default) and Direct3D 12, written to override.cfg and used from the next
## start (some GPU overlays hook Direct3D 12 more reliably).

signal changed(text: String)

const SAVE_PATH: String = "user://settings.json"
const TEST_PATH: String = "user://test_settings.json"
const UNCAPPED: int = 0
const DRIVER_SETTING: String = "rendering/rendering_device/driver.windows"
const DRIVERS: Array[String] = ["vulkan", "d3d12"]
const OVERRIDE_FILE: String = "override.cfg"

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


## The Windows rendering driver chosen for the next start.
func windows_driver() -> String:
	var path: String = override_path()
	var config := ConfigFile.new()
	if config.load(path) == OK:
		return String(config.get_value("rendering", "rendering_device/driver.windows", DRIVERS[0]))
	return String(ProjectSettings.get_setting(DRIVER_SETTING, DRIVERS[0]))


func toggle_windows_driver() -> void:
	var next: String = DRIVERS[(DRIVERS.find(windows_driver()) + 1) % DRIVERS.size()]
	var config := ConfigFile.new()
	config.load(override_path())
	config.set_value("rendering", "rendering_device/driver.windows", next)
	config.save(override_path())
	changed.emit("Windows renderer: %s (restart the game to use it)" % ("Direct3D 12" if next == "d3d12" else
		"Vulkan"))


## override.cfg sits beside the project when run from the editor, beside the executable in an exported game
## (tests write to a scratch file in user://).
func override_path() -> String:
	if save_path == TEST_PATH:
		return "user://test_" + OVERRIDE_FILE
	if OS.has_feature("editor"):
		return "res://" + OVERRIDE_FILE
	return OS.get_executable_path().get_base_dir().path_join(OVERRIDE_FILE)


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
