class_name CaptainPhaseTwo
extends Node
## The Warden Captain's second phase, from half health: he shouts, flashes red, his aura
## grows busier, his wind-ups and recoveries get shorter and he walks faster. Phase-2-only
## attacks (the chip pulse, the Zephoot summon) unlock. Watches his Health on its own.

## Wind-ups take this share of their time in phase 2.
@export var wind_up_scale: float = 0.7
## Recoveries (punish windows) take this share of their time in phase 2.
@export var recovery_scale: float = 0.7
## He walks this much faster in phase 2.
@export var speed_scale: float = 1.3
@export var shout: String = "You're just stock!"
@export var health: Health
@export var speech_bubble: SpeechBubble
@export var hit_flash: HitFlash
@export var aura: CaptainAura

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


func _check() -> void:
	if is_active or health.is_dead() or health.current_health * 2 > health.max_health:
		return
	is_active = true
	speech_bubble.say(shout)
	hit_flash.flash(ApolloPalette.RED_LIGHT)
	aura.intensify()
