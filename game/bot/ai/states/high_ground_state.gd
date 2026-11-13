class_name HighGroundState
extends BotState
## Take the high ground: run to the nearest jump spot below a ledge or rock, face the top and leap up. From there its
## shots reach a little further. Done once landed (or if the jump spot turns out unusable).

const JUMP_TIME_LIMIT: float = 8.0
## Leaps only once it faces the landing (the leap goes the way it faces).
const FACING_TOLERANCE: float = 0.3

var _spot: Dictionary = {}
var _time: float = 0.0
var _jumped: bool = false
var _flew: bool = false


func enter() -> void:
	_time = 0.0
	_jumped = false
	_flew = false
	stop_looking()
	var spots: Array[Dictionary] = brain.woods.jump_spots_near(bot().global_position, Tuning.ai_f("tactics",
			"near_feature_reach"))
	done = spots.is_empty()
	if not done:
		_spot = spots[0]
		mover().go_to(_spot["from"], false, true)


func tick(delta: float) -> void:
	_time += delta
	if done:
		return
	if _jumped:
		_flew = _flew or bot().airborne()
		done = _flew and not bot().airborne()
	elif mover().arrived():
		mover().stop()
		look_at_point(_spot["to"])
		bot().aim_point = _spot["to"]
		var toward: Vector3 = (_spot["to"] as Vector3) - bot().global_position
		toward.y = 0.0
		_jumped = bot().forward().angle_to(toward) < FACING_TOLERANCE and use_role("leap")
	done = done or _time > JUMP_TIME_LIMIT


## Taking the high ground is a plan: once decided it runs to the landing (or its time limit).
func committed() -> bool:
	return not done
