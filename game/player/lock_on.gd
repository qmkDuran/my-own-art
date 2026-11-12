class_name LockOn
extends Node
## Tab lock-on: only onto a bot you can currently see and within range. The camera then keeps it framed and
## movement strafes around it. Losing sight of it (it hides, or slips behind cover) for a moment breaks the lock.

var target: Creature
var _candidate: Creature
var _sight: PlayerSight
var _rig: CameraRig
var _player: Creature
var _unseen_for: float = 0.0


func setup(player: Creature, candidate: Creature, sight: PlayerSight, rig: CameraRig) -> void:
	_player = player
	_candidate = candidate
	_sight = sight
	_rig = rig
	name = "LockOn"


func target_locked() -> bool:
	return target != null


func toggle() -> void:
	if target_locked():
		release()
	elif _sight.can_see_bot() and _in_range():
		target = _candidate
		_rig.lock_target = target
		_unseen_for = 0.0


func release() -> void:
	target = null
	_rig.lock_target = null


func _physics_process(delta: float) -> void:
	if not target_locked():
		return
	_unseen_for = 0.0 if _sight.sees_bot else _unseen_for + delta
	if target.is_dead() or _unseen_for > Tuning.f("lock_on", "lose_sight_time") or not _in_range():
		release()


func _in_range() -> bool:
	return _player.global_position.distance_to(_candidate.global_position) <= Tuning.f("lock_on", "max_range")
