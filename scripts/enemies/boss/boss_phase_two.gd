class_name BossPhaseTwo
extends Node
## A boss's second phase, from half health: it shouts, flashes red, its aura grows busier,
## its wind-ups and recoveries get shorter and it walks faster. Phase-2-only attacks (e.g.
## the Captain's chip pulse) unlock. Watches the boss's Health on its own.

## Wind-ups take this share of their time in phase 2.
@export var wind_up_scale: float = 0.7
## Recoveries (punish windows) take this share of their time in phase 2.
@export var recovery_scale: float = 0.7
## The boss walks this much faster in phase 2.
@export var speed_scale: float = 1.3
@export var shout: String = "You're just stock!"
@export var health: Health
@export var speech_bubble: SpeechBubble
@export var hit_flash: HitFlash
@export var aura: BossAura

var is_active: bool = false


func _ready() -> void:
	health.hit_taken.connect(func(_amount: int, _critical: bool, _type: Health.DamageType) -> void: _check())


## How long a wind-up takes now, as a share of its normal time.
func current_wind_up_scale() -> float:
	return wind_up_scale if is_active else 1.0


func current_recovery_scale() -> float:
	return recovery_scale if is_active else 1.0


func current_speed_scale() -> float:
	return speed_scale if is_active else 1.0


## Back to phase 1 (the fight reset after the player fell).
func reset() -> void:
	is_active = false
	aura.calm()


func _check() -> void:
	if is_active or health.is_dead() or health.current_health * 2 > health.max_health:
		return
	is_active = true
	speech_bubble.say(shout)
	hit_flash.flash(ApolloPalette.RED_LIGHT)
	aura.intensify()
