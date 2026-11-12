extends Node
## Autoload "NoiseBus": carries the sounds creatures make (steps, attacks, impacts, a trap being set) to anyone
## who listens, so hearing and the player's rustle cue never need to know who made a sound.

signal noise_made(source: Node3D, origin: Vector3, radius: float, kind: String)


func emit_noise(source: Node3D, origin: Vector3, radius: float, kind: String) -> void:
	noise_made.emit(source, origin, radius, kind)
