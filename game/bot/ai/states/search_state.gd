class_name SearchState
extends BotState
## Search: go to where the player probably is (last known spot pushed along its heading), look around, then check
## hiding spots: first the player's learned favourites, then those along its heading, nearest first. It sneaks and
## listens; a new sound moves the search there. Close to a bush it sees whoever hides in it; up close it spots
## snares. When it runs out of places it drops the lead and goes back to patrolling.

enum Step { GO_TO_CLUE, LOOK_AROUND, CHECK_SPOT, PAUSE }

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


func tick(delta: float) -> void:
	if senses().take_fresh_lead():
		_go_to_clue()
	_time += delta
	match _step:
		Step.GO_TO_CLUE:
			if mover().arrived():
				_pause(Step.LOOK_AROUND, Tuning.f("bot", "look_around_time"))
		Step.CHECK_SPOT:
			if mover().arrived():
				_pause(Step.PAUSE, Tuning.f("bot", "bush_check_pause"))
		_:
			if not _look_around(delta) and not _check_next_spot():
				_give_up()
	if _time > Tuning.f("bot", "search_time"):
		_give_up()


## Hiding spots in the order to check them: learned favourites first (as much as the difficulty uses memory), then
## those ahead along the player's heading, nearest first.
func spots_to_check() -> Array[HidingSpot]:
	var clue: Vector3 = brain.predicted_target()
	var nearby: Array[HidingSpot] = Prediction.hideouts_ahead(brain.woods.hiding_spots, clue, Vector3.ZERO)
	nearby = nearby.filter(func(spot: HidingSpot) -> bool:
		return spot.global_position.distance_to(clue) <= Tuning.f("bot", "search_radius"))
	var ahead: Array[HidingSpot] = Prediction.hideouts_ahead(nearby, clue, senses().last_known_heading)
	nearby.sort_custom(func(a: HidingSpot, b: HidingSpot) -> bool:
		return _priority(a, ahead, clue) > _priority(b, ahead, clue))
	var chosen: Array[HidingSpot] = nearby.slice(0, Tuning.i("bot", "search_bush_count"))
	if not chosen.is_empty() and brain.memory_use() * brain.model.favourite_weight(chosen[0]) > 0.0:
		brain.bark("It remembers you like the %s." % ("tall grass" if chosen[0].kind == "grass" else "bushes"))
	return chosen


func _priority(spot: HidingSpot, ahead: Array[HidingSpot], clue: Vector3) -> float:
	var nearness: float = 1.0 - spot.global_position.distance_to(clue) / Tuning.f("bot", "search_radius")
	var on_heading: float = 1.0 if ahead.has(spot) else 0.0
	return nearness + on_heading + 2.0 * brain.memory_use() * brain.model.favourite_weight(spot)


func _go_to_clue() -> void:
	_step = Step.GO_TO_CLUE
	stop_looking()
	mover().go_to(brain.predicted_target(), false)
	_spots = spots_to_check()


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


func _give_up() -> void:
	senses().has_lead = false
	done = true
