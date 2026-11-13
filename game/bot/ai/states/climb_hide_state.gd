class_name ClimbHideState
extends BotState
## Climb and hide: climb a marked tree near where the player is expected and wait in its crown, unseen. Shoot down
## if it can; drop on the player when it passes close below. Gives up after a while.

const DROP_DISTANCE: float = 3.5

var _waited: float = 0.0
var _tree: Vector3 = Vector3.INF


func enter() -> void:
	_waited = 0.0
	stop_looking()
	_tree = brain.woods.climbable_near(brain.predicted_target(), Tuning.ai_f("tactics", "near_feature_reach"))
	done = _tree == Vector3.INF
	if not done:
		mover().go_to(_tree, true, true)


func tick(delta: float) -> void:
	var climb: ClimbMove = bot().move_with_role("climb") as ClimbMove
	if done or climb == null:
		done = true
		return
	if not climb.perched():
		if mover().arrived() and not bot().busy() and not use_role("climb"):
			done = true
		return
	_waited += delta
	look_at_point(senses().last_known_position)
	aim_at_clue(true)
	if senses().sees_target and distance_to_clue() <= DROP_DISTANCE or _waited > Tuning.f("bot", "ambush_wait"):
		climb.drop_down()
		done = true
	elif senses().sees_target:
		use_role("ranged")


## Once decided it climbs and waits; it gives up by its own timer or when the player comes close.
func committed() -> bool:
	return not done
