class_name CreatureActions
extends RefCounted
## Starts what the player asks the creature to do, one action at a time: a jab (toward the
## cursor, or at a clicked enemy once in reach) or a dodge. One exception: a dodge can cancel
## a jab mid-punch (and a skill during its wind-up), so the player can usually escape (like
## Path of Exile 2's dodge roll). Skills are started by the SkillBar itself.
##
## The Creature calls `update` every frame; this reads its components and starts the action.

var _creature: Creature


func _init(creature: Creature) -> void:
	_creature = creature


func update() -> void:
	_cancel_jab_recovery_to_move()
	_start_requested_action()


## Jabbing, dodging or casting: the creature can't start anything else, or steer.
func is_busy() -> bool:
	return _creature.melee_attack.is_attacking or _creature.dodge.is_dodging or _creature.skill_bar.is_casting()


## Animation cancel: once the jab's hit has landed, a fresh order to move cuts the
## rest of its recovery short, so walking away after a punch feels instant.
## Not while the player is still asking to attack, so holding attack chains full jabs.
func _cancel_jab_recovery_to_move() -> void:
	if not _creature.melee_attack.can_cancel_by_moving() or not _wants_to_move():
		return
	if _creature.player_input.wants_to_attack() or _creature.mouse_orders.has_attack_target():
		return
	_creature.melee_attack.cancel()


func _wants_to_move() -> bool:
	return _creature.player_input.get_move_direction() != Vector2.ZERO or _creature.mouse_orders.has_destination()


func _start_requested_action() -> void:
	var input := _creature.player_input
	var orders := _creature.mouse_orders
	if input.wants_to_dodge() and _can_dodge():
		_creature.melee_attack.cancel()
		_creature.skill_bar.cancel_cast()
		_start_dodge()
	elif is_busy() or not _creature.melee_attack.is_ready():
		return
	elif input.wants_to_attack():
		_start_jab(_creature.aim_direction())
	elif orders.is_attack_target_in_reach():
		_start_jab(orders.direction_to_attack_target(_creature.facing.as_vector()))
		orders.note_jabbed_attack_target()


## Ready, allowed by the skill bar, and its feet aren't rooted to the ground.
func _can_dodge() -> bool:
	return _creature.dodge.is_ready() and _creature.skill_bar.allows_dodge() and not Rooted.is_rooting(_creature)


func _start_jab(jab_direction: Vector2) -> void:
	_creature.mouse_orders.stop_walking()
	_creature.player_input.consume_attack_buffer()
	_creature.facing.look_toward(jab_direction)
	_creature.melee_attack.start(jab_direction)
	_creature.animator.replay_animation(_creature.melee_attack.current_animation, _creature.facing)


## The dodge is a big kangaroo hop, so it reuses the hop animation, with its trails.
func _start_dodge() -> void:
	var dodge := _creature.dodge
	var dodge_direction := _dodge_direction()
	_creature.facing.look_toward(dodge_direction)
	dodge.start(dodge_direction)
	_creature.animator.replay_animation("hop", _creature.facing)
	_creature.afterimage_trail.play_for(dodge.dodge_duration)
	_creature.speed_trail.play_for(dodge.dodge_duration)
	_creature.speed_lines.play_for(dodge.dodge_duration, dodge_direction)


## Dodge where the player is steering with the arrow keys; otherwise toward the cursor.
func _dodge_direction() -> Vector2:
	var steering := _creature.player_input.get_move_direction()
	if steering != Vector2.ZERO:
		return steering
	_creature.mouse_orders.clear()
	return _creature.aim_direction()
