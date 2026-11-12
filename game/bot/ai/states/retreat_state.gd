class_name RetreatState
extends BotState
## Retreat: badly hurt, the bot slips away to the best refuge (far from the player, covered, ideally concealed in a
## bush, with ways out) and rests there to heal. If it is seen at its refuge it moves to another.


func enter() -> void:
	brain.since_retreat = 0.0
	stop_looking()
	_go_to_refuge()


func tick(_delta: float) -> void:
	if mover().arrived() and senses().sees_target:
		_go_to_refuge()


func _go_to_refuge() -> void:
	if not go_to_tactical("retreat", bot().global_position, false):
		done = true
