class_name CaptainDefeat
extends Node
## The Warden Captain's death, played out in beats so it lands: he staggers, his visor
## flickers out, then his control chip shorts in a burst of cyan sparks, the stolen light
## bursts out of him as a shower of XP motes, the HUD announces the victory and he fades.
## He can't be hit or bumped into from the first beat.

@export var sprite: SingleViewAnimator
@export var collision_shape: CollisionShape2D
## Frees the light (XP) at the spark burst; its own burst on death should be off.
@export var light_drop: LightDrop
@export var aura: CaptainAura
@export var screen_shake: ScreenShake
## The ring effect for the burst.
@export var shockwave_scene: PackedScene
## Seconds he staggers before the visor goes.
@export var stagger_seconds: float = 0.9
## Seconds the visor flickers before the chip bursts.
@export var flicker_seconds: float = 0.8
## Seconds he takes to fade away after the burst.
@export var fade_seconds: float = 0.6
## Where on his body the chip bursts, relative to his feet.
@export var burst_offset: Vector2 = Vector2(0, -16)

@onready var captain: WardenCaptain = get_parent()


func play() -> void:
	captain.remove_from_group(EnemyReactions.ENEMIES_GROUP)
	collision_shape.set_deferred("disabled", true)
	sprite.replay_animation("stagger")
	_shake(1.0, stagger_seconds)
	await get_tree().create_timer(stagger_seconds).timeout
	sprite.replay_animation("defeated")
	await get_tree().create_timer(flicker_seconds).timeout
	_burst()
	var fade := captain.create_tween()
	fade.tween_property(sprite, "modulate:a", 0.0, fade_seconds)
	fade.tween_callback(captain.queue_free)


func _burst() -> void:
	var chip_position := captain.global_position + burst_offset
	ChipSparkBurst.spawn(captain.get_parent(), chip_position)
	if shockwave_scene != null:
		Shockwave.spawn(shockwave_scene, captain.get_parent(), chip_position, 26.0, 0.4, Color(ApolloPalette.SKY_LIGHT, 0.9))
		Shockwave.spawn(shockwave_scene, captain.get_parent(), chip_position, 44.0, 0.6, Color(ApolloPalette.SKY, 0.7))
	aura.hide()
	light_drop.burst()
	_shake(3.0, 0.35)
	BossHealthBar.announce_defeat(captain, captain.display_name)


func _shake(strength: float, seconds: float) -> void:
	if screen_shake != null:
		screen_shake.shake(strength, seconds)
