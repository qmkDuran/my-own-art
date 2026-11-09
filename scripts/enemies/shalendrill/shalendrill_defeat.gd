class_name ShalendrillDefeat
extends Node
## The Shalendrill's fall, in beats: it reels, sinks to its knuckles while the cyan light in
## its eyes and stone flickers out, then the AI God's chip shorts in a burst of cyan sparks
## and the Glimra light it was robbed of bursts free as a shower of XP motes. The HUD
## announces the victory and it fades. It can't be hit or bumped into from the first beat.

@export var sprite: SingleViewAnimator
@export var collision_shape: CollisionShape2D
## Frees the light (XP) at the burst; its own burst on death should be off.
@export var light_drop: LightDrop
@export var aura: CaptainAura
@export var screen_shake: ScreenShake
@export var shockwave_scene: PackedScene
@export var reel_seconds: float = 0.8
@export var sink_seconds: float = 1.1
@export var fade_seconds: float = 0.8
## Where on its body the chip bursts, relative to its feet (the head).
@export var burst_offset: Vector2 = Vector2(0, -24)

@onready var boss: Shalendrill = get_parent()


func play() -> void:
	boss.remove_from_group(EnemyReactions.ENEMIES_GROUP)
	collision_shape.set_deferred("disabled", true)
	sprite.lift(0.0)
	sprite.replay_animation("hurt")
	_shake(1.5, reel_seconds)
	await get_tree().create_timer(reel_seconds).timeout
	sprite.replay_animation("defeated")
	_shake(1.0, 0.2)
	await get_tree().create_timer(sink_seconds).timeout
	_burst()
	var fade := boss.create_tween()
	fade.tween_property(sprite, "modulate:a", 0.0, fade_seconds)
	fade.tween_callback(boss.queue_free)


func _burst() -> void:
	var chip_position := boss.global_position + burst_offset
	ChipSparkBurst.spawn(boss.get_parent(), chip_position)
	if shockwave_scene != null:
		Shockwave.spawn(shockwave_scene, boss.get_parent(), chip_position, 30.0, 0.4, Color(ApolloPalette.SKY_LIGHT, 0.9))
		Shockwave.spawn(shockwave_scene, boss.get_parent(), boss.global_position, 56.0, 0.7, Color(ApolloPalette.GOLD, 0.7))
	aura.hide()
	light_drop.burst()
	_shake(3.0, 0.4)
	BossHealthBar.announce_defeat(boss, boss.display_name)


func _shake(strength: float, seconds: float) -> void:
	if screen_shake != null:
		screen_shake.shake(strength, seconds)
