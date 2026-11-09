extends Node
## Every creature species the player has met (registered as the "CreatureLog" autoload).
##
## The first time a species is met, `discovered` fires so the HUD can show the
## "new creature" card. SaveGame keeps the species met between sessions. This is the
## bestiary's data: a Creature Log screen (parked) will list each species met with what it
## does and tips (see DESIGN.md, "Creature Log").

## info = { "species": String, "name": String, "element": String, "portrait": Texture2D }
signal discovered(info: Dictionary)

var _seen := {}


func has_seen(species: String) -> bool:
	return _seen.has(species)


## Records a species; announces it only the first time.
func discover(info: Dictionary) -> void:
	if has_seen(info["species"]):
		return
	_seen[info["species"]] = info
	discovered.emit(info)


## What SaveGame writes: the species met (their portraits and names come from the creatures).
func to_save_data() -> Dictionary:
	return {"species": _seen.keys()}


## Restores a save (an empty one means none met). Loaded species won't be announced again.
func load_save_data(data: Dictionary) -> void:
	_seen.clear()
	for species in SaveData.read_strings(data, "species"):
		_seen[species] = {"species": species}
