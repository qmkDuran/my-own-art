class_name HuntState
extends BotState
## Hunt: chase openly toward the player. If the player slips out of sight, swing wide around the last known spot
## (a flank around whatever blocks the view) before falling back to a search.

var _lost_for: float = 0.0
var _flanking: bool = false


func enter() -> void:
	_lost_for = 0.0
	_flanking = false
	stop_looking()


func tick(delta: float) -> String:
	if senses().sees_target:
		_lost_for = 0.0
		_flanking = false
		if distance_to_target() <= Tuning.f("bot", "fight_range"):
			return "fight"
		mover().go_to(target().global_position, false)
		return ""
	_lost_for += delta
	if not _flanking:
		_flanking = true
		mover().go_to(_flank_point(), false)
	if _lost_for > Tuning.f("bot", "hunt_memory") or mover().arrived():
		return "search"
	return ""


func _flank_point() -> Vector3:
	var clue: Vector3 = senses().last_known_position
	var approach: Vector3 = clue - bot().global_position
	var side: Vector3 = Vector3(approach.x, 0.0, approach.z).normalized().cross(Vector3.UP)
	return clue + side * BotBrain.random_side(brain.rng) * Tuning.f("bot", "flank_offset")
