class_name Projectile
extends Node3D
## A shot from a ranged move (a glob, a cinder, a jet of water, a seed, mud, sap). Each physics step it sweeps a
## small sphere along its path, so it never tunnels: the first tree, rock, log, wall, slope or creature stops it.
## Cinders set tall grass they fly through alight; water puts fire out and leaves mud where it lands.

signal landed(result: String, where: Vector3)

const TRAIL_COUNT: int = 3
const TRAIL_SPACING: float = 0.22
const TRAIL_SHRINK: float = 0.22
const SPLAT_DISTANCE: float = 0.05
const CREATURE_SPLAT_SIZE: float = 0.4

var shooter: Creature
var move: Move
var direction: Vector3 = Vector3.FORWARD
var travel_left: float = 0.0
var damage: float = 0.0
var _query := PhysicsShapeQueryParameters3D.new()
var _speed: float = 0.0


func setup(from_move: Move, from: Vector3, toward: Vector3, reach: float, shot_damage: float) -> void:
	move = from_move
	shooter = from_move.creature
	position = from
	direction = toward
	travel_left = reach
	damage = shot_damage
	_speed = move.number("speed")
	var sphere := SphereShape3D.new()
	sphere.radius = move.number("radius")
	_query.shape = sphere
	_query.collision_mask = Layers.PROJECTILE_HITS
	_query.exclude = [shooter.get_rid()]
	add_to_group("projectiles")
	_build_view(sphere.radius)


func velocity() -> Vector3:
	return direction * _speed


func _physics_process(delta: float) -> void:
	var step: float = minf(_speed * delta, travel_left)
	var motion: Vector3 = direction * step
	_query.transform = Transform3D(Basis.IDENTITY, global_position)
	_query.motion = motion
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var fractions: PackedFloat32Array = space.cast_motion(_query)
	if fractions[1] < 1.0:
		global_position += motion * fractions[1]
		_impact(space)
		return
	global_position += motion
	travel_left -= step
	if move.spec.get("ignite", false) and shooter.woods != null:
		shooter.woods.ignite_at(global_position)
	if travel_left <= 0.0:
		_finish("fizzle", Vector3.UP)


func _impact(space: PhysicsDirectSpaceState3D) -> void:
	_query.transform = Transform3D(Basis.IDENTITY, global_position)
	_query.motion = Vector3.ZERO
	var info: Dictionary = space.get_rest_info(_query)
	var normal: Vector3 = info.get("normal", -direction)
	var collider: Object = instance_from_id(int(info.get("collider_id", 0))) if info.has("collider_id") else null
	if collider is Creature:
		var victim := collider as Creature
		var hit: bool = victim.take_hit(damage, shooter, move.ambush, move.id)
		if hit:
			move.apply_on_hit(victim)
		_finish("hit" if hit else "dodged", normal)
	elif collider is CollisionObject3D and (collider as CollisionObject3D).collision_layer & Layers.OBSTACLE:
		_finish("blocked", normal)
	else:
		_finish("ground", normal)


func _finish(result: String, normal: Vector3) -> void:
	var where: Vector3 = global_position
	NoiseBus.emit_noise(shooter, where, Tuning.f("noise", "impact_radius"), "impact")
	_terrain_effects(result, where)
	if result != "fizzle":
		var size: float = CREATURE_SPLAT_SIZE if result in ["hit", "dodged"] else 1.0
		SplatFx.spawn(get_parent(), where + normal * SPLAT_DISTANCE, normal, size, _color())
	landed.emit(result, where)
	queue_free()


func _terrain_effects(result: String, where: Vector3) -> void:
	var woods: Woods = shooter.woods
	if woods == null:
		return
	if move.spec.get("ignite", false):
		woods.ignite_at(where)
	if move.spec.get("douse", false):
		woods.douse_at(where)
	if move.spec.get("mud", false) and result == "ground":
		woods.spawn_mud(where)


func _color() -> Color:
	return Tuning.color(Tuning.creatures["glow"][move.spec["color"]])


func _build_view(radius: float) -> void:
	var material: StandardMaterial3D = SplatFx.shot_material(_color())
	for k: int in TRAIL_COUNT + 1:
		var ball := SphereMesh.new()
		ball.radius = radius * (1.0 - TRAIL_SHRINK * k)
		ball.height = ball.radius * 2.0
		var view := MeshInstance3D.new()
		view.mesh = ball
		view.material_override = material
		view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		view.position = -direction * TRAIL_SPACING * k
		add_child(view)
