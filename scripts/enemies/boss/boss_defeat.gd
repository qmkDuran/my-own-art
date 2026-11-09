@abstract
class_name BossDefeat
extends Node
## A boss's death, played out in beats so it lands. The boss leaves the fight at once (it
## can't be hit or bumped into), plays its own beats (`_play_beats`: a stagger, a sink to its
## knees...), then the AI God's chip shorts in a burst of cyan sparks and shockwave rings
## (`_spawn_burst_rings`), the stolen light bursts out of it as a shower of XP motes, the HUD
## announces the victory and the boss fades away.

## How hard the screen shakes at the chip burst.
const BURST_SHAKE_STRENGTH := 3.0

@export var sprite: SingleViewAnimator
@export var collision_shape: CollisionShape2D
## Frees the light (XP) at the burst; its own burst on death should be off.
@export var light_drop: LightDrop
@export var aura: BossAura
@export var screen_shake: ScreenShake
## The ring effect for the burst.
@export var shockwave_scene: PackedScene
## Seconds the boss takes to fade away after the burst.
@export var fade_seconds: float = 0.6
## Where on its body the chip bursts, relative to its feet.
@export var burst_offset: Vector2 = Vector2(0, -16)
## Seconds the screen shakes at the chip burst.
@export var burst_shake_seconds: float = 0.35

@onready var boss: SpeciesEnemy = get_parent()


func play() -> void:
	boss.remove_from_group(EnemyReactions.ENEMIES_GROUP)
	collision_shape.set_deferred("disabled", true)
	@warning_ignore("redundant_await")  # every BossDefeat's beats are a coroutine
	await _play_beats()
	_burst()
	var fade := boss.create_tween()
	fade.tween_property(sprite, "modulate:a", 0.0, fade_seconds)
	fade.tween_callback(boss.queue_free)


## The boss's own beats before the chip bursts (poses, shakes and pauses).
@abstract func _play_beats() -> void


## The burst's shockwave rings, from the chip at `chip_position` (only with a shockwave_scene).
@abstract func _spawn_burst_rings(chip_position: Vector2) -> void


func _burst() -> void:
	var chip_position := boss.global_position + burst_offset
	ChipSparkBurst.spawn(boss.get_parent(), chip_position)
	if shockwave_scene != null:
		_spawn_burst_rings(chip_position)
	aura.hide()
	light_drop.burst()
	_shake(BURST_SHAKE_STRENGTH, burst_shake_seconds)
	BossHealthBar.announce_defeat(boss, boss.display_name)


func _spawn_ring(at: Vector2, radius: float, seconds: float, color: Color) -> void:
	Shockwave.spawn(shockwave_scene, boss.get_parent(), at, radius, seconds, color)


func _shake(strength: float, seconds: float) -> void:
	if screen_shake != null:
		screen_shake.shake(strength, seconds)
