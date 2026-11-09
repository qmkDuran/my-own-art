extends Node
## The last checkpoint the player reached (registered as the "Checkpoints" autoload): where
## they get back up after falling (see Respawner), and where loading a save puts them.
##
## One checkpoint for the whole game, kept with the zone it is in, so a checkpoint from
## another zone is never used. SaveGame saves it like any other system
## (`to_save_data` / `load_save_data`).

## Fired when another checkpoint becomes the last one reached (SaveGame saves then).
signal changed

## The zone scene the checkpoint is in ("" before any).
var zone_path: String = ""
## Its Checkpoint's `checkpoint_id` ("" before any).
var checkpoint_id: String = ""


## Makes checkpoint `id` in `zone` the place to get back up. Returns false if it already was.
func reach(zone: String, id: String) -> bool:
	if zone == zone_path and id == checkpoint_id:
		return false
	zone_path = zone
	checkpoint_id = id
	changed.emit()
	return true


## The last checkpoint reached in `zone`, or "" if none was reached there.
func last_in_zone(zone: String) -> String:
	return checkpoint_id if zone == zone_path else ""


## The zone `asker` is in (the running scene's file), "" if none.
static func zone_of(asker: Node) -> String:
	var scene := asker.get_tree().current_scene
	return scene.scene_file_path if scene != null else ""


## What SaveGame writes.
func to_save_data() -> Dictionary:
	return {"zone": zone_path, "id": checkpoint_id}


## Restores the saved checkpoint (an empty save means none yet).
func load_save_data(data: Dictionary) -> void:
	zone_path = _read_string(data, "zone")
	checkpoint_id = _read_string(data, "id")


static func _read_string(data: Dictionary, key: String) -> String:
	var value: Variant = data.get(key)
	return value if value is String else ""
