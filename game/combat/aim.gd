class_name Aim
extends Node
## Where the Lamplighter is aiming: a ray from the centre of the screen (the crosshair) into the world, stopping at
## the first wall or enemy, or a locked-on enemy (Tab picks the enemy nearest the crosshair within reach and the
## camera follows it; Tab again lets go). Also keeps the "combat stance": for a moment after any attack the
## camera tightens over the shoulder and the player turns to face where the crosshair points.

signal lock_changed(target: Enemy)

const NEAR_SKIP: float = 0.5

var point: Vector3 = Vector3.ZERO
var target: Enemy
var pointed: Enemy
var _stance: float = 0.0
var _player: Player
var _camera: CameraRig
var _roster: Roster


func setup(player: Player, camera: CameraRig, roster: Roster) -> void:
	name = "Aim"
	_player = player
	_camera = camera
	_roster = roster


## Where shots leave from: the lantern's glass.
func muzzle() -> Vector3:
	return _player.lantern.light.global_position


func direction_from(from: Vector3) -> Vector3:
	return from.direction_to(point)


## Called by every attack: holds the over-the-shoulder stance for a moment.
func engage() -> void:
	_stance = Tuning.number("combat", "aim", "stance_seconds")


func in_stance() -> bool:
	return _stance > 0.0


func toggle_lock() -> void:
	if target != null:
		lock(null)
		return
	var eye: Camera3D = _camera.camera
	var best: Enemy = null
	var best_angle: float = deg_to_rad(Tuning.number("combat", "aim", "lock_cone_deg"))
	for enemy: Enemy in _roster.enemies:
		var to: Vector3 = enemy.centre() - eye.global_position
		var angle: float = to.angle_to(-eye.global_basis.z)
		if to.length() < Tuning.number("combat", "aim", "lock_range") and angle < best_angle:
			best = enemy
			best_angle = angle
	lock(best)


## Locks on to an enemy (null lets go).
func lock(enemy: Enemy) -> void:
	target = enemy
	_camera.lock_target = enemy
	lock_changed.emit(enemy)


func _physics_process(delta: float) -> void:
	_stance = maxf(_stance - delta, 0.0)
	if target != null and (not is_instance_valid(target) or not target.is_alive()):
		lock(null)
	if target != null:
		point = target.centre()
		pointed = target
		return
	var eye: Camera3D = _camera.camera
	var forward: Vector3 = -eye.global_basis.z
	var from: Vector3 = eye.global_position + forward * (eye.global_position.distance_to(_player.global_position) +
		NEAR_SKIP)
	var far: Vector3 = from + forward * Tuning.number("combat", "aim", "range")
	var query := PhysicsRayQueryParameters3D.create(from, far, Layers.WORLD, [_player.get_rid()])
	var wall: Dictionary = _player.get_world_3d().direct_space_state.intersect_ray(query)
	var end: Vector3 = wall["position"] if not wall.is_empty() else far
	var hit: Dictionary = _roster.sweep(from, end, 0.0)
	pointed = hit["enemy"] if not hit.is_empty() else null
	point = pointed.centre() if pointed != null else end
