class_name AshGuard
extends SkillAction
## Ash Guard (Ember Tree, Bruiser): Emberoo plants his feet and raises his gloves. For
## `guard_duration` seconds he takes `damage_taken_percent`% damage and shoves don't move
## him (see Unshakable.share_of_push). Pressing the key again, attacking or dodging drops it.
##
## Only the guard itself lives here: Counter Punch listens for hits taken while it is up.
## Its numbers fill the Ash Guard facts in the tree and the stats panel's Guard row.

## Seconds the guard lasts if nothing drops it.
@export var guard_duration: float = 1.2
## Share of each hit's damage taken while guarding, in percent.
@export var damage_taken_percent: int = 50
## Whose damage the guard soaks.
@export var health: Health
## Attacking drops the guard (the jab then starts on the next frame).
@export var player_input: PlayerInput

var _time_guarding: float = 0.0
var _shimmer: AshGuardShimmer = null


func _physics_process(delta: float) -> void:
	if not is_casting:
		return
	_time_guarding += delta
	if _time_guarding >= guard_duration or player_input.wants_to_attack():
		_drop_guard()


func start(caster: Node2D, aim_direction: Vector2) -> void:
	super.start(caster, aim_direction)
	_time_guarding = 0.0
	health.damage_taken_scale = damage_taken_percent / 100.0
	_shimmer = AshGuardShimmer.new()
	caster.add_child(_shimmer)
	_shimmer.face(aim_direction)


func cancel() -> void:
	if is_casting:
		_drop_guard()


func ends_on_second_press() -> bool:
	return true


## Seconds of guard left (0 when not guarding).
func time_left() -> float:
	return maxf(0.0, guard_duration - _time_guarding) if is_casting else 0.0


func _drop_guard() -> void:
	is_casting = false
	health.damage_taken_scale = 1.0
	if is_instance_valid(_shimmer):
		_shimmer.queue_free()
	_shimmer = null
