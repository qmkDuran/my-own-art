class_name BotState
extends RefCounted
## One way of acting, carried out while the brain's utility choice stays the same. enter() and exit() bracket it;
## tick() runs every physics frame. A state sets `done` when it has finished (the brain then decides again at once)
## and answers committed() while it must not be interrupted (mid-bite, setting a snare).

var brain: BotBrain
var done: bool = false


func _init(owner: BotBrain) -> void:
	brain = owner


func begin() -> void:
	done = false
	enter()


func enter() -> void:
	pass


func exit() -> void:
	pass


func tick(_delta: float) -> void:
	pass


func committed() -> bool:
	return bot().busy()


func bot() -> Creature:
	return brain.bot


func target() -> Creature:
	return brain.target


func senses() -> Perception:
	return brain.senses


func mover() -> BotMover:
	return brain.mover


## Distance to where the player is known (or last known) to be.
func distance_to_clue() -> float:
	return bot().global_position.distance_to(senses().last_known_position)


func look_at_point(point: Vector3) -> void:
	bot().has_look_target = true
	bot().look_target = point


func stop_looking() -> void:
	bot().has_look_target = false


## Goes to the best spot for a tactical purpose around a centre, judged against the player's last known spot.
## Returns false when there is none.
func go_to_tactical(purpose: String, around: Vector3, sneak: bool) -> bool:
	var best: Dictionary = brain.tactics.best(purpose, around, senses().last_known_position)
	if best.is_empty():
		return false
	mover().go_to(best["pos"], sneak, true)
	return true
