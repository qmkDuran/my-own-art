class_name PlayerWatch
extends RefCounted
## Tells a HUD widget when the player creature has changed (e.g. a team swap brought another
## creature in), so it can bind to the new one's components. Ask `has_changed` each frame.

## Instance id of the player last seen (0 = none).
var _player_id: int = 0


## True on the first call after the player became a different creature (or appeared, or left).
func has_changed(asker: Node) -> bool:
	var player := PlayerFinder.find(asker)
	var player_id := player.get_instance_id() if player != null else 0
	if player_id == _player_id:
		return false
	_player_id = player_id
	return true
