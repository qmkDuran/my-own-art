class_name BotState
extends RefCounted
## One state of the bot's mind. enter() and exit() bracket it; tick() runs every physics frame and returns the name
## of the next state, or "" to stay. Shared helpers keep the states short and readable.

var brain: BotBrain


func _init(owner: BotBrain) -> void:
	brain = owner


func enter() -> void:
	pass


func exit() -> void:
	pass


func tick(_delta: float) -> String:
	return ""


func bot() -> Creature:
	return brain.bot


func target() -> Creature:
	return brain.target


func senses() -> Perception:
	return brain.senses


func mover() -> BotMover:
	return brain.mover


func distance_to_target() -> float:
	return bot().global_position.distance_to(target().global_position)


func look_at_point(point: Vector3) -> void:
	bot().has_look_target = true
	bot().look_target = point


func stop_looking() -> void:
	bot().has_look_target = false


## Where to go after losing sight: fight up close if visible, else chase, else search.
func pursuit_state() -> String:
	if senses().sees_target:
		return "fight" if distance_to_target() <= Tuning.f("bot", "fight_range") else "hunt"
	return "search"
