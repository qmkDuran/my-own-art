extends Node
## Every creature species the player has met (registered as the "CreatureLog" autoload).
##
## The first time a species is met, `discovered` fires so the HUD can show the
## "new creature" card. Later this will be saved to disk and shown on a Creature Log screen.

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
