class_name AfterimageTrail
extends Node
## Leaves fading, fire-tinted copies of a sprite behind it, so fast moves are easy to read.
## The copies keep the sprite's Awakened look and take Emberoo's fire tint (EmberooFlameColors).

## The sprite to copy.
@export var sprite: AnimatedSprite2D
## Seconds between each copy.
@export var spawn_interval: float = 0.05
## Seconds each copy takes to fade away.
@export var fade_time: float = 0.25


func play_for(duration: float) -> void:
	var time_left := duration
	while time_left > 0.0:
		_spawn_copy()
		await get_tree().create_timer(spawn_interval).timeout
		time_left -= spawn_interval


func _spawn_copy() -> void:
	var copy := Sprite2D.new()
	copy.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	copy.flip_h = sprite.flip_h
	copy.material = sprite.material
	copy.modulate = EmberooFlameColors.afterimage_tint()
	# Added to the world so the copy stays behind while the creature moves on.
	sprite.owner.get_parent().add_child(copy)
	copy.global_position = sprite.global_position
	# Same layer as the ground (drawn on top of it); creatures sit one layer higher.
	copy.z_index = 0

	var fade := copy.create_tween()
	fade.tween_property(copy, "modulate:a", 0.0, fade_time)
	fade.tween_callback(copy.queue_free)
