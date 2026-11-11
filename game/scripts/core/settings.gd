class_name Settings
extends RefCounted
## Player settings: music and sound volume (0-10) and text speed, kept in user://settings.json.

const PATH: String = "user://settings.json"
const MAX_VOLUME: int = 10
const SPEEDS: Dictionary = {"Slow": 0.5, "Normal": 1.0, "Fast": 2.0, "Instant": 50.0}

static var music: int = 7
static var sounds: int = 8
static var text_speed: String = "Normal"


static func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if d is Dictionary:
		music = clampi(int(d.get("music", music)), 0, MAX_VOLUME)
		sounds = clampi(int(d.get("sounds", sounds)), 0, MAX_VOLUME)
		text_speed = String(d.get("text_speed", text_speed)) if SPEEDS.has(d.get("text_speed", "")) else text_speed


static func save_settings() -> void:
	var f: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"music": music, "sounds": sounds, "text_speed": text_speed}))


static func text_mult() -> float:
	return float(SPEEDS[text_speed])


static func volume_db(level: int) -> float:
	return linear_to_db(maxf(float(level) / MAX_VOLUME, 0.0001))


static func next_speed() -> void:
	var keys: Array = SPEEDS.keys()
	text_speed = String(keys[(keys.find(text_speed) + 1) % keys.size()])
