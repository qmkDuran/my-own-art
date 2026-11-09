class_name ShalendrillDefeat
extends BossDefeat
## The Shalendrill's fall (see BossDefeat): it reels, then sinks to its knuckles while the
## cyan light in its eyes and stone flickers out, then the chip bursts and the Glimra light it
## was robbed of bursts free.

const REEL_SHAKE_STRENGTH := 1.5
## A short thud as it sinks.
const SINK_SHAKE_STRENGTH := 1.0
const SINK_SHAKE_SECONDS := 0.2
## The burst's rings: a bright one round the chip, and a wide gold one at its feet.
const CHIP_RING_RADIUS := 30.0
const CHIP_RING_SECONDS := 0.4
const CHIP_RING_COLOR := Color(ApolloPalette.SKY_LIGHT, 0.9)
const GROUND_RING_RADIUS := 56.0
const GROUND_RING_SECONDS := 0.7
const GROUND_RING_COLOR := Color(ApolloPalette.GOLD, 0.7)

@export var reel_seconds: float = 0.8
@export var sink_seconds: float = 1.1


func _init() -> void:
	fade_seconds = 0.8
	burst_offset = Vector2(0, -24)
	burst_shake_seconds = 0.4


func _play_beats() -> void:
	sprite.lift(0.0)
	sprite.replay_animation("hurt")
	_shake(REEL_SHAKE_STRENGTH, reel_seconds)
	await Wait.seconds(self, reel_seconds)
	sprite.replay_animation("defeated")
	_shake(SINK_SHAKE_STRENGTH, SINK_SHAKE_SECONDS)
	await Wait.seconds(self, sink_seconds)


func _spawn_burst_rings(chip_position: Vector2) -> void:
	_spawn_ring(chip_position, CHIP_RING_RADIUS, CHIP_RING_SECONDS, CHIP_RING_COLOR)
	_spawn_ring(boss.global_position, GROUND_RING_RADIUS, GROUND_RING_SECONDS, GROUND_RING_COLOR)
