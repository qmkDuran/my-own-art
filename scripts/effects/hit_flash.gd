class_name HitFlash
extends Node
## Flashes a sprite bright white for a moment when it gets hit.
##
## Uses self_modulate, so it never fights with fades that use modulate.

@export var sprite: CanvasItem
## How bright the flash starts (1.0 is normal).
@export var flash_brightness: float = 4.0
## Seconds for the flash to fade back to normal.
@export var flash_time: float = 0.12


func flash() -> void:
	sprite.self_modulate = Color(flash_brightness, flash_brightness, flash_brightness)
	var fade := sprite.create_tween()
	fade.tween_property(sprite, "self_modulate", Color.WHITE, flash_time)
