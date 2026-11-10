extends Node
## The player's progress: hero, chapter, flags, inventory, health, and the checkpoint used
## for retry and Continue. Saved as JSON at SAVE_PATH.

const SAVE_PATH := "user://save_slot1.json"
const SAVE_VERSION := 1
const DEFAULT_MAX_HP := 10

var flags := FlagStore.new()
var inventory := Inventory.new()
var gender := "female"
var skin_tone := 2
var hair_style := ""
var hero_name := ""
var chapter := 1
var zone_id := ""
var spawn_id := ""
## When set, the player appears here instead of at spawn_id (mid-zone checkpoints).
var spawn_position: Variant = null
var max_hp := DEFAULT_MAX_HP
var hp := DEFAULT_MAX_HP

var _checkpoint: Dictionary = {}


func _ready() -> void:
	flags.changed.connect(func(flag: String, value: Variant) -> void: Events.flag_changed.emit(flag, value))


func new_game(chosen_gender: String, chosen_skin_tone: int = 2, chosen_hair: String = "") -> void:
	gender = chosen_gender
	skin_tone = chosen_skin_tone
	hair_style = chosen_hair if not chosen_hair.is_empty() else default_hair(gender)
	var hero: Dictionary = DB.heroes.get(gender, {})
	hero_name = String(hero.get("name", "You"))
	chapter = 1
	flags.load_dict({})
	inventory.clear()
	max_hp = DEFAULT_MAX_HP
	hp = max_hp
	var start: Dictionary = DB.heroes.get("start", {})
	zone_id = String(start.get("zone", "house"))
	spawn_id = String(start.get("spawn", "bed"))
	spawn_position = null
	_checkpoint = snapshot()


func hero_art(kind: String) -> String:
	var hero: Dictionary = DB.heroes.get(gender, {})
	return String(hero.get(kind, ""))


## Art id of the hero's hair layer (a sheet with the same frame layout as the body).
func hair_art() -> String:
	return hair_art_for(gender, hair_style)


static func hair_art_for(for_gender: String, style: String) -> String:
	for option: Variant in hair_options(for_gender):
		if String((option as Dictionary).get("id", "")) == style:
			return String(option["art"])
	return ""


static func hair_options(for_gender: String) -> Array:
	return (DB.heroes.get(for_gender, {}) as Dictionary).get("hair_styles", [])


static func default_hair(for_gender: String) -> String:
	var options := hair_options(for_gender)
	return String((options[0] as Dictionary).get("id", "")) if not options.is_empty() else ""


static func skin_tones() -> Array:
	return DB.heroes.get("skin_tones", [])


func skin_color() -> Color:
	var tones := skin_tones()
	if tones.is_empty():
		return Color("c89070")
	var tone: Dictionary = tones[clampi(skin_tone, 0, tones.size() - 1)]
	return Color.from_string(String(tone.get("color", "#c89070")), Color("c89070"))


## Replaces {HERO}, {KID}, {THEY}, {THEM}, {THEIR}, {THEIRS}, {THEMSELF} (any case) in dialogue text.
## Values come from data/heroes.json ("name" and "pronouns" of the chosen hero, "text_variables").
func substitute(text: String) -> String:
	if not text.contains("{"):
		return text
	var hero: Dictionary = DB.heroes.get(gender, {})
	var values: Dictionary = (hero.get("pronouns", {}) as Dictionary).duplicate()
	values["hero"] = hero_name
	values.merge(DB.heroes.get("text_variables", {}))
	for key: String in values.keys():
		var value := String(values[key])
		text = text.replace("{%s}" % key, value).replace("{%s}" % key.to_upper(), value)
	return text


func set_hp(value: int) -> void:
	hp = clampi(value, 0, max_hp)
	Events.player_health_changed.emit(hp, max_hp)


func heal(amount: int) -> void:
	set_hp(hp + amount)


func snapshot() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"gender": gender,
		"skin_tone": skin_tone,
		"hair_style": hair_style,
		"hero_name": hero_name,
		"chapter": chapter,
		"zone": zone_id,
		"spawn": spawn_id,
		"position": _vector_to_array(spawn_position),
		"flags": flags.to_dict(),
		"inventory": inventory.to_dict(),
		"max_hp": max_hp,
		"hp": hp,
	}


func restore(data: Dictionary) -> void:
	gender = String(data.get("gender", "female"))
	skin_tone = int(data.get("skin_tone", 2))
	hair_style = String(data.get("hair_style", default_hair(gender)))
	hero_name = String(data.get("hero_name", "You"))
	chapter = int(data.get("chapter", 1))
	zone_id = String(data.get("zone", "house"))
	spawn_id = String(data.get("spawn", ""))
	spawn_position = _array_to_vector(data.get("position"))
	flags.load_dict(data.get("flags", {}))
	inventory.load_dict(data.get("inventory", {}))
	max_hp = int(data.get("max_hp", DEFAULT_MAX_HP))
	hp = int(data.get("hp", max_hp))


## Records where the player is now and writes the save file.
func save_checkpoint(position: Variant = null) -> void:
	spawn_position = position
	hp = max(hp, ceili(max_hp * 0.5))
	_checkpoint = snapshot()
	_write_save(_checkpoint)
	Events.checkpoint_saved.emit()


func restore_checkpoint() -> void:
	restore(_checkpoint)
	hp = max_hp


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_save() -> bool:
	if not has_save():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary:
		push_error("Save file is corrupt: %s" % SAVE_PATH)
		return false
	_checkpoint = parsed
	restore(_checkpoint)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _write_save(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))


static func _vector_to_array(value: Variant) -> Variant:
	if value is Vector2:
		var v: Vector2 = value
		return [v.x, v.y]
	return null


static func _array_to_vector(value: Variant) -> Variant:
	if value is Array and (value as Array).size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return null
