class_name BotState
extends RefCounted
## One way of acting, carried out while the brain's utility choice stays the same. enter() and exit() bracket it;
## tick() runs every physics frame. A state sets `done` when it has finished (the brain then decides again at once)
## and answers committed() while it must not be interrupted (mid-strike, underground, up a tree).

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


## Uses the bot's equipped move of a role (aimed at its current aim point). False if it has none or cannot now.
func use_role(role: String) -> bool:
	var move: Move = bot().move_with_role(role)
	return move != null and bot().try_move(bot().slot_of(move))


## Points the bot's aim at the player's last known chest, leading shots on its observed movement.
func aim_at_clue(lead: bool) -> void:
	var chest: Vector3 = senses().last_known_position + Vector3.UP * Tuning.f("perception", "chest_height")
	var velocity: Vector3 = senses().observed_velocity if lead else Vector3.ZERO
	var move: Move = bot().move_with_role("ranged")
	var speed: float = move.number("speed") if move != null else INF
	bot().aim_point = Prediction.lead_point(bot().mouth_position(), chest, velocity, speed) if lead else chest


## Goes to the best spot for a tactical purpose around a centre, judged against the player's last known spot.
## Returns false when there is none.
func go_to_tactical(purpose: String, around: Vector3, sneak: bool) -> bool:
	var best: Dictionary = brain.tactics.best(purpose, around, senses().last_known_position)
	if best.is_empty():
		return false
	mover().go_to(best["pos"], sneak, true)
	return true
