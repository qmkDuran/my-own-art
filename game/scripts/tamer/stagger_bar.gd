class_name StaggerBar
extends RefCounted
## A creature's stagger: hits fill it (element weaknesses much faster); when it fills the creature is STAGGERED for
## a few seconds: it reels (stunned), takes more damage, and your gauge fills faster on it. It drains when the
## creature is left alone for a moment.

signal staggered

var c: Creature
var value: float = 0.0
var staggered_t: float = 0.0
var _quiet: float = 0.0


func _init(creature: Creature) -> void:
	c = creature


func S() -> Dictionary:
	return TamerData.rule("combat.stagger")


func max_value() -> float:
	return c.rec.max_life() * float(S()["max_per_life"])


func frac() -> float:
	return clampf(value / maxf(max_value(), 1.0), 0.0, 1.0)


func is_staggered() -> bool:
	return staggered_t > 0.0


func damage_taken() -> float:
	return float(S()["damage_taken"]) if is_staggered() else 1.0


func add(amount: float) -> void:
	if is_staggered() or amount <= 0.0:
		return
	_quiet = float(S()["decay_after"])
	value += amount
	if value >= max_value():
		value = 0.0
		staggered_t = float(S()["time"])
		c.stun_t = maxf(c.stun_t, staggered_t)
		c.view.reel(staggered_t)
		TamerFx.word(c.global_position, "STAGGERED!", Pal.c("gold"), UiDraw.TITLE)
		CameraRig.shake(0.35)
		Audio.sfx("slam", -4.0, 0.8)
		staggered.emit()


func tick(delta: float) -> void:
	staggered_t = maxf(0.0, staggered_t - delta)
	_quiet -= delta
	if _quiet <= 0.0:
		value = maxf(0.0, value - float(S()["decay"]) * delta)
