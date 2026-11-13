class_name BurnGrassState
extends BotState
## Burn them out: the player is probably hiding in a tall-grass patch, so the bot gets a clear line to it and sets it
## alight with a fire move (Cinder Spit from range, Kindle up close). Burnt grass hides no one until it regrows.

## Fire from a quarter of the move's reach outside the patch edge (or half its reach, if nearer).
const EDGE_SHARE: float = 0.25

var _patch: HidingSpot


func enter() -> void:
	_patch = brain.suspect_grass()
	var fire: Move = brain.fire_move()
	done = _patch == null or fire == null
	if not done:
		var reach: float = BotFacts.effective_range(fire)
		var from: Vector3 = _patch.global_position + (bot().global_position - _patch.global_position).normalized() \
				* minf(reach * 0.5, _patch.radius + reach * EDGE_SHARE)
		mover().go_to(from, true)


func exit() -> void:
	stop_looking()


func tick(_delta: float) -> void:
	var fire: Move = brain.fire_move()
	if done or fire == null or not _patch.conceals():
		done = true
		return
	look_at_point(_patch.global_position)
	bot().aim_point = _patch.global_position + Vector3.UP * Tuning.f("perception", "chest_height")
	var in_reach: bool = bot().global_position.distance_to(_patch.global_position) <= BotFacts.effective_range(fire)
	if in_reach and Sight.clear(bot().get_world_3d(), bot().mouth_position(), bot().aim_point):
		mover().stop()
		if bot().try_move(bot().slot_of(fire)):
			brain.bark("It burns the grass you hide in.")
			done = true


## Burning the grass out is a plan: once decided it gets into reach and fires (or the grass is gone).
func committed() -> bool:
	return not done
