class_name SearchState
extends BotState
## Search: go to the last known spot, look around, then check the bushes and grass nearby, nearest to where the
## player was heading first, sneaking and listening. A new sound moves the search there. Close to a bush it sees
## whoever hides in it; up close it also spots snares. Gives up after a while and patrols again.

enum Step { GO_TO_CLUE, LOOK_AROUND, CHECK_SPOT, PAUSE }

const HEADING_LEAD: float = 4.0

var _step: Step = Step.GO_TO_CLUE
var _time: float = 0.0
var _step_left: float = 0.0
var _look_angle: float = 0.0
var _spots: Array[HidingSpot] = []


func enter() -> void:
	_time = 0.0
	senses().searching_carefully = true
	_go_to_clue()


func exit() -> void:
	senses().searching_carefully = false
	stop_looking()


func tick(delta: float) -> String:
	if senses().sees_target:
		return pursuit_state()
	if senses().take_fresh_lead():
		_go_to_clue()
	_time += delta
	if _time > Tuning.f("bot", "search_time"):
		return "patrol"
	match _step:
		Step.GO_TO_CLUE:
			if mover().arrived():
				_pause(Step.LOOK_AROUND, Tuning.f("bot", "look_around_time"))
		Step.CHECK_SPOT:
			if mover().arrived():
				_pause(Step.PAUSE, Tuning.f("bot", "bush_check_pause"))
		_:
			if not _look_around(delta) and not _check_next_spot():
				return "patrol"
	return ""


func _go_to_clue() -> void:
	_step = Step.GO_TO_CLUE
	stop_looking()
	mover().go_to(senses().last_known_position, false)
	_spots = _spots_to_check()


func _pause(step: Step, duration: float) -> void:
	_step = step
	_step_left = duration


## Turns slowly on the spot; false once the pause is over.
func _look_around(delta: float) -> bool:
	_step_left -= delta
	_look_angle += Tuning.f("bot", "look_around_speed") * delta
	look_at_point(bot().global_position + Vector3(sin(_look_angle), 0.0, cos(_look_angle)))
	return _step_left > 0.0


func _check_next_spot() -> bool:
	if _spots.is_empty():
		return false
	stop_looking()
	_step = Step.CHECK_SPOT
	mover().go_to(_spots.pop_front().global_position, true)
	return true


func _spots_to_check() -> Array[HidingSpot]:
	var clue: Vector3 = senses().last_known_position
	var guess: Vector3 = clue + senses().last_known_heading * HEADING_LEAD
	var nearby: Array[HidingSpot] = []
	for spot: HidingSpot in brain.woods.hiding_spots:
		if spot.global_position.distance_to(clue) <= Tuning.f("bot", "search_radius"):
			nearby.append(spot)
	nearby.sort_custom(func(a: HidingSpot, b: HidingSpot) -> bool:
		return a.global_position.distance_to(guess) < b.global_position.distance_to(guess))
	return nearby.slice(0, Tuning.i("bot", "search_bush_count"))
