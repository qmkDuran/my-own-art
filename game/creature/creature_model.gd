class_name CreatureModel
extends Node3D
## The creature's look and body language: walk cycle, each move's telegraph (its pose and coloured glow from the
## move data), the dodge roll, hit flash, stagger shake, sinking out of sight when burrowed or submerged, the state
## marker above the head ("!" noticed, "?" searching) and lying down when beaten.

const STRIDE_RATE: float = 2.6
const STRIDE_SWING: float = 0.55
const BOB_HEIGHT: float = 0.04
## Wind-up poses by name: (head pitch, body lean at full wind-up).
const POSES: Dictionary = { "lunge": Vector2(0.45, 0.18), "rear": Vector2(0.6, 0.0), "crouch": Vector2(-0.2, -0.25),
	"spin": Vector2(0.0, 0.1), "none": Vector2.ZERO }
const SINK_DEPTH: float = -1.0
const SINK_SPEED: float = 3.0
const LUNGE_LEAN: float = -0.3
const STAGGER_SHAKE: float = 0.12
const STAGGER_RATE: float = 40.0
const POSE_SHARPNESS: float = 14.0
const GLOW_MAX_SCALE: float = 1.6
const FLASH_COLOR: Color = Color(1, 1, 1)
const DEAD_TILT: float = 1.45
const DEAD_DARKEN: float = 0.45
const DEAD_DROP: float = 0.45
const GLOW_MIN_SCALE: float = 0.4
const BODY_GLOW_SHARE: float = 0.12
const TAIL_WAG_SHARE: float = 0.5
const MARKER_HEIGHT: float = 1.75
const MARKER_SIZE: int = 150
const MARKER_PIXEL: float = 0.006
const MARKER_OUTLINE: int = 28

var torso: Node3D
var head: Node3D
var tail: Node3D
var glow: MeshInstance3D
var legs: Array[Node3D] = []
var body_material: StandardMaterial3D
var belly_material: StandardMaterial3D
var accent_material: StandardMaterial3D
var _base_color: Color
var _hip_height: float = 0.0
var _stride: float = 0.0
var _clock: float = 0.0
var _flash_left: float = 0.0
var _roll: float = 0.0
var _marker: Label3D


func build(look: Dictionary) -> void:
	CreatureParts.build(self, look)
	_base_color = body_material.albedo_color
	_hip_height = torso.position.y
	_marker = Label3D.new()
	_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_marker.font_size = MARKER_SIZE
	_marker.pixel_size = MARKER_PIXEL
	_marker.outline_size = MARKER_OUTLINE
	_marker.no_depth_test = true
	_marker.position.y = MARKER_HEIGHT
	add_child(_marker)


func show_marker(text: String, color: Color) -> void:
	_marker.text = text
	_marker.modulate = color


func flash_hit() -> void:
	_flash_left = Tuning.f("creature", "hit_flash_time")


func show_dead() -> void:
	torso.rotation.z = DEAD_TILT
	torso.position.y = _hip_height * DEAD_DROP
	body_material.albedo_color = _base_color.darkened(DEAD_DARKEN)
	glow.visible = false
	_marker.text = ""


func animate(delta: float, creature: Creature) -> void:
	rotation.y = creature.yaw
	if creature.is_dead():
		return
	_walk(delta, creature)
	_pose(delta, creature)
	_telegraph_glow(creature)
	_flash(delta)


func _walk(delta: float, creature: Creature) -> void:
	var speed: float = 0.0 if creature.is_rooted() else creature.horizontal_speed()
	_stride += speed * STRIDE_RATE * delta
	var swing: float = sin(_stride) * STRIDE_SWING * minf(speed / Tuning.f("creature", "run_speed"), 1.0)
	for k: int in legs.size():
		var opposite: float = 1.0 if k % 3 == 0 else -1.0
		legs[k].rotation.x = swing * opposite
	torso.position.y = _hip_height + absf(sin(_stride)) * BOB_HEIGHT * minf(speed, 1.0)
	if tail != null:
		tail.rotation.y = sin(_stride * TAIL_WAG_SHARE) * STRIDE_SWING * TAIL_WAG_SHARE


func _pose(delta: float, creature: Creature) -> void:
	var head_goal: float = 0.0
	var lean_goal: float = 0.0
	for move: Move in creature.moves:
		if move.phase == Ability.Phase.WINDUP:
			var pose: Vector2 = POSES.get(move.spec["pose"], Vector2.ZERO)
			head_goal = pose.x
			lean_goal = pose.y * move.windup_progress()
		elif move.phase == Ability.Phase.ACTIVE and move is MeleeMove:
			lean_goal = LUNGE_LEAN
	var blend: float = clampf(POSE_SHARPNESS * delta, 0.0, 1.0)
	head.rotation.x = lerpf(head.rotation.x, head_goal, blend)
	torso.rotation.x = lerpf(torso.rotation.x, lean_goal, blend)
	_clock += delta
	torso.rotation.z = sin(_clock * STAGGER_RATE) * STAGGER_SHAKE if creature.is_staggered() else 0.0
	_roll_pose(delta, creature)
	_sink(delta, creature)


## Burrowed or submerged, the body sinks out of sight (only its own player sees the top of it).
func _sink(delta: float, creature: Creature) -> void:
	var goal: float = SINK_DEPTH if creature.traversal.deep() else 0.0
	position.y = move_toward(position.y, goal, SINK_SPEED * delta)


func _roll_pose(delta: float, creature: Creature) -> void:
	if creature.roll.protects():
		_roll += TAU * delta / Tuning.f("dodge", "duration")
	else:
		_roll = 0.0
	var local_dir: Vector3 = creature.dodge_direction().rotated(Vector3.UP, -creature.yaw)
	var axis: Vector3 = Vector3.UP.cross(local_dir).normalized()
	if _roll > 0.0 and axis.length() > 0.0:
		torso.basis = Basis(axis, _roll)


func _telegraph_glow(creature: Creature) -> void:
	var winding: Move = null
	for move: Move in creature.moves:
		if move.phase == Ability.Phase.WINDUP and move.spec["glow"] != "":
			winding = move
	glow.visible = winding != null
	body_material.emission_enabled = winding != null
	if winding == null:
		return
	var color: Color = Tuning.color(Tuning.creatures["glow"][winding.spec["glow"]])
	var progress: float = winding.windup_progress()
	glow.scale = Vector3.ONE * lerpf(GLOW_MIN_SCALE, GLOW_MAX_SCALE, progress)
	(glow.material_override as StandardMaterial3D).albedo_color = color
	body_material.emission = color
	body_material.emission_energy_multiplier = float(Tuning.creatures["glow"]["strength"]) * progress * BODY_GLOW_SHARE


func _flash(delta: float) -> void:
	_flash_left = maxf(0.0, _flash_left - delta)
	body_material.albedo_color = FLASH_COLOR if _flash_left > 0.0 else _base_color

