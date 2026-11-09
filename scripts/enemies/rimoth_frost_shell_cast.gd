class_name RimothFrostShellCast
extends Node
## A Rimoth's support spell: every few seconds it picks one nearby ally without a shell, holds
## its wings up and pours a chill beam into it (ChillBeam) for a moment, then the ally gets a
## frost shell (FrostShell) that soaks the next hits. Kill the Rimoth first.
##
## The Rimoth decides when to start it and plays the pose; this picks the ally and does the
## timing, the beam and the shell.

## Seconds the cast takes (the beam is visible all that time).
@export var cast_time: float = 0.7
## Seconds from one cast to the next.
@export var seconds_between_casts: float = 4.0
## Seconds after it first notices the player before the first cast.
@export var first_cast_delay: float = 1.5
## It only shells allies within this distance, in pixels.
@export var cast_range: float = 130.0
## Damage each shell soaks.
@export var shell_soak: int = 2

var _seconds_until_ready: float = 0.0
var _target: Node2D
var _beam: ChillBeam

@onready var rimoth: Node2D = get_parent()


func _ready() -> void:
	_seconds_until_ready = first_cast_delay


func count_down(delta: float) -> void:
	_seconds_until_ready = maxf(0.0, _seconds_until_ready - delta)


## Ready, with an ally in range that has no shell yet.
func should_cast() -> bool:
	return _seconds_until_ready <= 0.0 and _nearest_unshelled_ally() != null


## Starts pouring the beam into the nearest ally without a shell.
func start() -> void:
	_target = _nearest_unshelled_ally()
	if _target != null:
		_beam = ChillBeam.spawn(rimoth.get_parent(), rimoth, _target)


## Call every frame of the cast with the seconds since it started. True once it's done.
func update(seconds_casting: float) -> bool:
	if is_instance_valid(_beam):
		_beam.progress = seconds_casting / cast_time
	if seconds_casting < cast_time:
		return false
	if is_instance_valid(_target) and _target.is_in_group(EnemyReactions.ENEMIES_GROUP):
		FrostShell.apply_to(_target, shell_soak)
	_finish()
	return true


## Called off (e.g. it got hit): no shell, and the beam goes out.
func cancel() -> void:
	_finish()


func _finish() -> void:
	_seconds_until_ready = seconds_between_casts
	if is_instance_valid(_beam):
		_beam.queue_free()
	_beam = null
	_target = null


func _nearest_unshelled_ally() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := cast_range
	for ally: Node2D in get_tree().get_nodes_in_group(EnemyReactions.ENEMIES_GROUP):
		if ally == rimoth or not ally is Enemy or FrostShell.has_shell(ally):
			continue
		var distance := rimoth.global_position.distance_to(ally.global_position)
		if distance <= nearest_distance:
			nearest = ally
			nearest_distance = distance
	return nearest
