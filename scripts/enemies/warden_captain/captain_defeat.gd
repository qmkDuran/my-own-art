class_name CaptainDefeat
extends BossDefeat
## The Warden Captain's death (see BossDefeat): he staggers, his visor flickers out, then his
## control chip bursts.

## The shake while he staggers.
const STAGGER_SHAKE_STRENGTH := 1.0
## The burst's two rings round the chip: a tight bright one and a wide soft one.
const INNER_RING_RADIUS := 26.0
const INNER_RING_SECONDS := 0.4
const INNER_RING_COLOR := Color(ApolloPalette.SKY_LIGHT, 0.9)
const OUTER_RING_RADIUS := 44.0
const OUTER_RING_SECONDS := 0.6
const OUTER_RING_COLOR := Color(ApolloPalette.SKY, 0.7)

## Seconds he staggers before the visor goes.
@export var stagger_seconds: float = 0.9
## Seconds the visor flickers before the chip bursts.
@export var flicker_seconds: float = 0.8


func _play_beats() -> void:
	sprite.replay_animation("stagger")
	_shake(STAGGER_SHAKE_STRENGTH, stagger_seconds)
	await Wait.seconds(self, stagger_seconds)
	sprite.replay_animation("defeated")
	await Wait.seconds(self, flicker_seconds)


func _spawn_burst_rings(chip_position: Vector2) -> void:
	_spawn_ring(chip_position, INNER_RING_RADIUS, INNER_RING_SECONDS, INNER_RING_COLOR)
	_spawn_ring(chip_position, OUTER_RING_RADIUS, OUTER_RING_SECONDS, OUTER_RING_COLOR)
