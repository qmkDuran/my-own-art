extends Node
## The Glimmer Shards the player has found (registered as the "ShardInventory" autoload).
##
## Shards are hand-placed (see DESIGN.md, "Drops and progression resources"), each with its
## own ID, so a shard that was picked up never shows again, even after loading a save.
## Socketing them into skills comes later; for now this only records which were found.

signal collected(shard_id: String)

var _found: Dictionary = {}


func has_found(shard_id: String) -> bool:
	return _found.has(shard_id)


## Records a shard; does nothing if it was already found.
func collect(shard_id: String) -> void:
	if has_found(shard_id):
		return
	_found[shard_id] = true
	collected.emit(shard_id)


## What SaveGame writes: the IDs of the shards found.
func to_save_data() -> Dictionary:
	return {"found": _found.keys()}


## Restores a save (an empty one means none found).
func load_save_data(data: Dictionary) -> void:
	_found.clear()
	for shard_id in SaveData.read_strings(data, "found"):
		_found[shard_id] = true
