class_name Heat
extends Node
## Emberoo's resource. Landing jabs builds Heat; skills spend it (see SkillBar).
## After a few seconds without landing a hit, Heat cools off one pip at a time.

signal heat_changed(heat: int, max_heat: int)

@export var max_heat: int = 5
## Heat gained each time a jab lands (however many enemies it hits).
@export var heat_per_landed_jab: int = 1
## Seconds without landing a hit before Heat starts cooling off.
@export var cool_off_delay: float = 3.0
## Seconds between each pip lost while cooling off.
@export var seconds_per_pip_lost: float = 0.8

var heat: int = 0
var _seconds_since_last_hit: float = 0.0
var _seconds_until_next_pip_lost: float = 0.0


func _process(delta: float) -> void:
	_seconds_since_last_hit += delta
	if heat == 0 or _seconds_since_last_hit < cool_off_delay:
		return
	_seconds_until_next_pip_lost -= delta
	if _seconds_until_next_pip_lost <= 0.0:
		_seconds_until_next_pip_lost = seconds_per_pip_lost
		_set_heat(heat - 1)


## Call when a jab lands on at least one enemy.
func on_hits_landed(_hit_count: int) -> void:
	_seconds_since_last_hit = 0.0
	_seconds_until_next_pip_lost = 0.0
	_set_heat(heat + heat_per_landed_jab)


func has(amount: int) -> bool:
	return heat >= amount


## Spends Heat if there's enough. Returns false (and spends nothing) otherwise.
func try_spend(amount: int) -> bool:
	if not has(amount):
		return false
	_set_heat(heat - amount)
	return true


func _set_heat(new_heat: int) -> void:
	var clamped := clampi(new_heat, 0, max_heat)
	if clamped == heat:
		return
	heat = clamped
	heat_changed.emit(heat, max_heat)
