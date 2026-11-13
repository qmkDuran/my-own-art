class_name Cooldown
extends RefCounted
## One ability's cooldown: ready when the time has run out; share() is how much of it is left (1 just used,
## 0 ready), which the HUD draws as a sweep.

var seconds: float = 0.0
var left: float = 0.0


func _init(length: float) -> void:
	seconds = length


func is_ready() -> bool:
	return left <= 0.0


func start() -> void:
	left = seconds


func tick(delta: float) -> void:
	left = maxf(left - delta, 0.0)


func share() -> float:
	return left / seconds if seconds > 0.0 else 0.0
