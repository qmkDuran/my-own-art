class_name SnareTrap
extends Node3D
## A snare on the ground. It springs on the owner's opponent when they step on it: rooted for a couple of seconds
## and a little damage, with a loud snap. The player's own snares show clearly (a gold ring); the bot's are faint
## to the player until they are close enough to spot one, the same distance the bot spots the player's.

const RING_RADIUS: float = 0.5
const RING_WIDTH: float = 0.09
const TEETH: int = 8
const TOOTH_SIZE: Vector3 = Vector3(0.09, 0.16, 0.05)
const TOOTH_CLOSE_ANGLE: float = 1.1
const SNAP_TIME: float = 0.12
const GROUND_PROBE: float = 2.0
const GLOW_ALPHA: float = 0.35
const LIFT: float = 0.03
const FAINT_ALPHA: float = 0.25

var owner_creature: Creature
var sprung: bool = false
var _arm_left: float = 0.0
var _teeth: Array[Node3D] = []
var _metal: StandardMaterial3D
var _glow_ring: MeshInstance3D


func setup(owner: Creature, at: Vector3) -> void:
	owner_creature = owner
	position = at
	_arm_left = Tuning.f("trap", "arm_delay")
	add_to_group("snares")


func _ready() -> void:
	_settle_on_ground()
	_build_view()


func _physics_process(delta: float) -> void:
	_arm_left -= delta
	var victim: Creature = owner_creature.opponent if is_instance_valid(owner_creature) else null
	_update_visibility(victim)
	if sprung or _arm_left > 0.0 or victim == null or victim.is_dead():
		return
	var offset: Vector3 = victim.global_position - global_position
	if Vector2(offset.x, offset.z).length() <= Tuning.f("trap", "trigger_radius"):
		_spring(victim)


func _spring(victim: Creature) -> void:
	sprung = true
	victim.root(Tuning.f("trap", "root_time"))
	victim.take_hit(Tuning.f("trap", "damage"), owner_creature, false, "trap")
	NoiseBus.emit_noise(owner_creature, global_position, Tuning.f("noise", "trap_snap_radius"), "snap")
	var snap: Tween = create_tween().set_parallel(true)
	for tooth: Node3D in _teeth:
		snap.tween_property(tooth, "rotation:x", TOOTH_CLOSE_ANGLE, SNAP_TIME)
	snap.chain().tween_interval(Tuning.f("trap", "root_time"))
	snap.chain().tween_callback(queue_free)


func _update_visibility(victim: Creature) -> void:
	var mine: bool = is_instance_valid(owner_creature) and owner_creature.see_through_cover
	var spotted: bool = victim != null and victim.global_position.distance_to(global_position) \
			<= Tuning.f("trap", "spot_distance")
	var clear: bool = mine or spotted or sprung
	_glow_ring.visible = mine
	_metal.albedo_color.a = 1.0 if clear else FAINT_ALPHA


func _settle_on_ground() -> void:
	var query := PhysicsRayQueryParameters3D.create(position + Vector3.UP * GROUND_PROBE,
			position + Vector3.DOWN * GROUND_PROBE, Layers.TERRAIN)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		position = hit["position"] + Vector3.UP * LIFT


func _build_view() -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = RING_RADIUS - RING_WIDTH
	ring.outer_radius = RING_RADIUS
	_metal = WoodsMaterials.solid("bark_dark").duplicate()
	_metal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var view := MeshInstance3D.new()
	view.mesh = ring
	view.material_override = _metal
	add_child(view)
	_glow_ring = MeshInstance3D.new()
	_glow_ring.mesh = ring
	_glow_ring.scale = Vector3.ONE * (1.0 + RING_WIDTH)
	_glow_ring.material_override = WoodsMaterials.glow(Tuning.color(Tuning.creatures["glow"]["trap"]), GLOW_ALPHA)
	add_child(_glow_ring)
	for k: int in TEETH:
		_add_tooth(TAU * k / TEETH, _metal)


func _add_tooth(angle: float, material: StandardMaterial3D) -> void:
	var pivot := Node3D.new()
	pivot.rotation.y = angle
	add_child(pivot)
	var holder := Node3D.new()
	holder.position = Vector3(0, 0, -(RING_RADIUS - RING_WIDTH * 0.5))
	pivot.add_child(holder)
	var tooth := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = TOOTH_SIZE
	tooth.mesh = prism
	tooth.material_override = material
	tooth.position = Vector3(0, TOOTH_SIZE.y * 0.5, 0)
	holder.add_child(tooth)
	_teeth.append(holder)
