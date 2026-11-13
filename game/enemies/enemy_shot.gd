class_name EnemyShot
extends Node3D
## An enemy's glowing shot (violet, so it never looks like the player's warm magic): flies straight, is stopped by
## the world and by the player's ward, and hurts the player if it reaches them (unless they blink through it).

const MAX_RANGE: float = 45.0
## A shot splashing on the ward pops smaller (it is close to the camera).
const WARD_SPLASH: float = 0.5

var damage: float = 0.0
var radius: float = 0.0
var warned: float = 0.0
var _roster: Roster
var _velocity: Vector3 = Vector3.ZERO
var _travelled: float = 0.0
var _look: Node3D


static func fire(roster: Roster, from: Vector3, direction: Vector3, speed: float, hurt: float, size: float,
		warning: float) -> EnemyShot:
	var shot := EnemyShot.new()
	shot.name = "EnemyShot"
	shot._roster = roster
	shot._velocity = direction.normalized() * speed
	shot.damage = hurt
	shot.radius = size
	shot.warned = warning
	roster.add_effect(shot, from)
	shot._look = EnemyShotLook.make(roster.fx, shot)
	roster.cue("enemy_shot", from)
	return shot


func _physics_process(delta: float) -> void:
	var from: Vector3 = global_position
	var to: Vector3 = from + _velocity * delta
	_travelled += _velocity.length() * delta
	var ward: Ward = _roster.ward
	if ward != null and ward.blocks(to):
		ward.absorb(to)
		_roster.fx.shot_pop(to, WARD_SPLASH)
		EnemyShotLook.leave(_look)
		queue_free()
		return
	var query := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	var wall: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not wall.is_empty():
		_pop(wall["position"])
		return
	global_position = to
	var chest: Vector3 = EnemyBrain.player_chest_of(_roster.player)
	if to.distance_to(chest) < radius + Tuning.number("combat", "player", "body_radius"):
		_roster.hurt_player(damage, warned)
		_pop(to)
	elif _travelled > MAX_RANGE:
		queue_free()


func _pop(at: Vector3) -> void:
	_roster.fx.shot_pop(at)
	EnemyShotLook.leave(_look)
	queue_free()
