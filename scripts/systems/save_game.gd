extends Node
## Keeps the player's progress between sessions (registered as the "SaveGame" autoload).
##
## One JSON file, SAVE_PATH, holds a `version` (for future migrations), the current zone
## and a section per system: Progression, Awakening, EmberTree, CreatureLog, ShardInventory,
## LinkRod (chips and scrap), Checkpoints (the last checkpoint reached), StoryFlags (story moments) and the player's TrainerAid. Each system writes and reads its own section (`to_save_data` /
## `load_save_data`), so this file never knows their insides.
##
## Loads in `_ready`, before the first zone is built, so everything that reads Progression
## or EmberTree in its own `_ready` (LevelUpBoost, the HUD, EmberTreeEffects) sees the
## loaded values. Saves on a level up, on Awakening, on learning or unlearning a node, on meeting a new
## species, on finding a Glimmer Shard, on reaching a checkpoint, every AUTOSAVE_SECONDS and on quitting. Writes go to a temp file that is then
## renamed over the save, so a crash mid-write never leaves half a file.
##
## The test arena turns saving off (DebugControls' `uses_save_file`), so it never loads
## or overwrites the real save.

const SAVE_PATH := "user://save_1.json"
const TEMP_PATH := SAVE_PATH + ".tmp"
## Where an unreadable save is moved, so it isn't overwritten and can still be looked at.
const UNREADABLE_PATH := "user://save_1.unreadable.json"
## Raise this when the layout changes, and teach `_migrate` to bring older files up to it.
const VERSION := 2
const AUTOSAVE_SECONDS := 60.0
const TRAINER_AID_NAME := "TrainerAid"

## Off for a session that must not touch the real save (the test arena).
var enabled: bool = true

var _is_loading: bool = false
var _is_save_queued: bool = false
## The saved zone, travelled to on start (see `_go_to_saved_zone`).
var _saved_zone_path: String = ""
## The saved Trainer's Aid section, given to the first TrainerAid that spawns.
var _pending_aid_data: Dictionary = {}


func _ready() -> void:
	_load_from_disk()
	Progression.leveled_up.connect(_queue_autosave.unbind(1))
	Awakening.stage_changed.connect(_queue_autosave.unbind(1))
	EmberTree.changed.connect(_queue_autosave)
	CreatureLog.discovered.connect(_queue_autosave.unbind(1))
	ShardInventory.collected.connect(_queue_autosave.unbind(1))
	LinkRod.changed.connect(_queue_autosave)
	Checkpoints.changed.connect(_queue_autosave)
	StoryFlags.changed.connect(_queue_autosave.unbind(1))
	get_tree().node_added.connect(_on_node_added)
	_start_autosave_timer()
	_go_to_saved_zone.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Writes the save now. Returns false when saving is off or the write failed.
func save_now() -> bool:
	if not enabled:
		return false
	return _write_atomically(JSON.stringify(_build_save(), "\t"))


## Turns saving off for this session and puts every system back to a fresh start, dropping
## what was loaded. Called by the test arena before its nodes read any progress.
func disable_for_session() -> void:
	if not enabled:
		return  # already off: keep the arena's progress across its restarts
	enabled = false
	reset_all()


## Puts every system back to a fresh start (level 0, nothing learned, met or found). The file is untouched.
func reset_all() -> void:
	_apply({})


## Deletes the save (if saving is on), starts fresh and reloads the zone.
func delete_save_and_restart() -> void:
	if enabled and has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	reset_all()
	get_tree().reload_current_scene.call_deferred()


func _build_save() -> Dictionary:
	var data := {
		"version": VERSION,
		"zone": _current_zone_path(),
		"progression": Progression.to_save_data(),
		"awakening": Awakening.to_save_data(),
		"ember_tree": EmberTree.to_save_data(),
		"creature_log": CreatureLog.to_save_data(),
		"shards": ShardInventory.to_save_data(),
		"link_rod": LinkRod.to_save_data(),
		"checkpoint": Checkpoints.to_save_data(),
		"story_flags": StoryFlags.to_save_data(),
	}
	var aid := PlayerFinder.find_component(self, TRAINER_AID_NAME) as TrainerAid
	if aid != null:
		data["trainer_aid"] = aid.to_save_data()
	return data


## Order matters: Progression first (it hands back every owned point), then Awakening
## (it opens the tree's rings, and an older save's stage follows from the level), then
## EmberTree (which spends the points again on the saved nodes).
func _apply(data: Dictionary) -> void:
	_is_loading = true
	Progression.load_save_data(SaveData.read_section(data, "progression"))
	Awakening.load_save_data(SaveData.read_section(data, "awakening"))
	EmberTree.load_save_data(SaveData.read_section(data, "ember_tree"))
	CreatureLog.load_save_data(SaveData.read_section(data, "creature_log"))
	ShardInventory.load_save_data(SaveData.read_section(data, "shards"))
	LinkRod.load_save_data(SaveData.read_section(data, "link_rod"))  # after the shards: they add its slots
	Checkpoints.load_save_data(SaveData.read_section(data, "checkpoint"))
	StoryFlags.load_save_data(SaveData.read_section(data, "story_flags"))
	_pending_aid_data = SaveData.read_section(data, "trainer_aid")
	var zone: Variant = data.get("zone")
	_saved_zone_path = zone if zone is String else ""
	_is_loading = false


func _load_from_disk() -> void:
	if not has_save():
		return
	var data := _read_save()
	if data.is_empty():
		push_warning("SaveGame: %s could not be read; moved it to %s and starting fresh." % [SAVE_PATH, UNREADABLE_PATH])
		DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(UNREADABLE_PATH))
		return
	_apply(data)


## The save's contents brought up to VERSION, or empty if it is damaged or from a newer game.
func _read_save() -> Dictionary:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(SAVE_PATH)) != OK or not json.data is Dictionary:
		return {}
	var parsed: Dictionary = json.data
	var version := SaveData.read_int(parsed, "version", 0, 0, SaveData.NO_LIMIT)
	if version > VERSION:
		return {}
	return _migrate(parsed, version)


## Brings an older save up to VERSION, one step per version. Version 0 (no "version" field)
## has the same layout as version 1.
## 1 → 2: story flags arrived with the hub. Older saves already had the Link Rod (before the
## Tinkerer handed it over), so they keep it.
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	if from_version < 2 and not data.has("story_flags"):
		data["story_flags"] = {"flags": [StoryFlags.LINK_ROD_GIVEN]}
	data["version"] = VERSION
	return data


func _write_atomically(text: String) -> bool:
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveGame: could not open %s (%s)." % [TEMP_PATH, error_string(FileAccess.get_open_error())])
		return false
	var is_written := file.store_string(text)
	file.close()
	if not is_written:
		push_error("SaveGame: could not write %s." % TEMP_PATH)
		return false
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(TEMP_PATH), ProjectSettings.globalize_path(SAVE_PATH))
	if error != OK:
		push_error("SaveGame: could not replace %s (%s)." % [SAVE_PATH, error_string(error)])
		return false
	return true


## Several changes in one frame (e.g. a level up and its point) make a single write.
func _queue_autosave() -> void:
	if not enabled or _is_loading or _is_save_queued:
		return
	_is_save_queued = true
	_autosave.call_deferred()


func _autosave() -> void:
	_is_save_queued = false
	save_now()


func _start_autosave_timer() -> void:
	var timer := Timer.new()
	timer.wait_time = AUTOSAVE_SECONDS
	timer.autostart = true
	timer.timeout.connect(_queue_autosave)
	add_child(timer)


func _current_zone_path() -> String:
	var scene := get_tree().current_scene
	return scene.scene_file_path if scene != null else _saved_zone_path


func _on_node_added(node: Node) -> void:
	if node is TrainerAid and not _pending_aid_data.is_empty():
		node.ready.connect(_restore_aid.bind(node), CONNECT_ONE_SHOT)


## Only the first Trainer's Aid after loading gets the saved charges (a fall refills it anyway: CreatureFall).
func _restore_aid(aid: TrainerAid) -> void:
	if enabled and not _pending_aid_data.is_empty():
		aid.load_save_data(_pending_aid_data)
	_pending_aid_data = {}


## When the game starts in the default zone but the save is in another, goes there.
func _go_to_saved_zone() -> void:
	var scene := get_tree().current_scene
	if not enabled or scene == null or not ResourceLoader.exists(_saved_zone_path):
		return
	var starts_in_default_zone: bool = scene.scene_file_path == ProjectSettings.get_setting("application/run/main_scene")
	if starts_in_default_zone and scene.scene_file_path != _saved_zone_path:
		get_tree().change_scene_to_file(_saved_zone_path)
