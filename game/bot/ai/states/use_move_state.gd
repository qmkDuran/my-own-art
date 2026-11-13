class_name UseMoveState
extends BotState
## One quick move of a role, then decide again: a buff before engaging, a debuff on the player, a defensive move
## against a wind-up it can see, a sense move while searching. Aims at the player's last known spot.

var _role: String
var _used: bool = false


func _init(owner: BotBrain, role: String) -> void:
	super(owner)
	_role = role


func enter() -> void:
	_used = false
	mover().stop()


func exit() -> void:
	stop_looking()


func tick(_delta: float) -> void:
	look_at_point(senses().last_known_position)
	aim_at_clue(true)
	if not _used:
		_used = use_role(_role)
		done = not _used
	else:
		done = not bot().busy()
