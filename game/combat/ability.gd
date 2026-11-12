class_name Ability
extends RefCounted
## Shared timing for a move: a wind-up (the readable telegraph), an active part, a recovery, and a cooldown that
## starts when the move fires. Subclasses fill in what happens at each step.

enum Phase { IDLE, WINDUP, ACTIVE, RECOVER }

var creature: Creature
var phase: Phase = Phase.IDLE
var cooldown: float
var cooldown_left: float = 0.0
var windup_time: float
var active_time: float
var recover_time: float
var _phase_left: float = 0.0


func _init(owner: Creature, windup: float, active: float, recover: float, cooldown_time: float) -> void:
	creature = owner
	windup_time = windup
	active_time = active
	recover_time = recover
	cooldown = cooldown_time


func is_ready() -> bool:
	return phase == Phase.IDLE and cooldown_left <= 0.0


func busy() -> bool:
	return phase != Phase.IDLE


func start() -> bool:
	if not is_ready():
		return false
	_phase_left = 0.0
	_on_start()
	_enter(Phase.WINDUP, windup_time)
	_advance_finished_phases()
	return true


func tick(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if phase == Phase.IDLE:
		return
	_phase_left -= delta
	_advance_finished_phases()


## Stops the move where it is (stagger, death); a move cut off in its wind-up keeps no cooldown.
func interrupt() -> void:
	phase = Phase.IDLE


func windup_progress() -> float:
	return 1.0 - _phase_left / windup_time if phase == Phase.WINDUP and windup_time > 0.0 else 0.0


func cooldown_share() -> float:
	return cooldown_left / cooldown if cooldown > 0.0 else 0.0


func _advance_finished_phases() -> void:
	while phase != Phase.IDLE and _phase_left <= 0.0:
		match phase:
			Phase.WINDUP:
				cooldown_left = cooldown
				_enter(Phase.ACTIVE, active_time)
				_on_release()
			Phase.ACTIVE:
				_enter(Phase.RECOVER, recover_time)
				_on_active_end()
			Phase.RECOVER:
				phase = Phase.IDLE


func _enter(next: Phase, duration: float) -> void:
	phase = next
	_phase_left = duration + minf(_phase_left, 0.0)


func _on_start() -> void:
	pass


func _on_release() -> void:
	pass


func _on_active_end() -> void:
	pass
