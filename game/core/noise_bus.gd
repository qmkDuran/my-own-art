extends Node
## Autoload "NoiseBus": carries the sounds creatures make (steps, attacks, impacts, landings, burrow rumbles) to anyone
## who listens (the bot's ears, the player's Keen Ears pings), so hearing never needs to know who made a sound.

signal noise_made(source: Node3D, origin: Vector3, radius: float, kind: String)


func emit_noise(source: Node3D, origin: Vector3, radius: float, kind: String) -> void:
	noise_made.emit(source, origin, radius, kind)
