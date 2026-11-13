class_name Telegraph
extends Node3D
## The warning before an enemy's ground attack: a circle or a line drawn on the ground (vfx_telegraph shader) whose
## fill grows over the wind-up (about 0.6 to 0.9 s, data/combat.json), with a warning chime. When the fill is
## full the attack lands: the player is hurt only if they are still inside, and a burst of violet flame shows it.
## Lines run from the caster along a direction. Logged on the roster so tests can check the warning time.

signal resolved(hit_player: bool)
signal finished

const SHADER: Shader = preload("res://shaders/vfx_telegraph.gdshader")
const LIFT: float = 0.06
const FLASH_SECONDS: float = 0.3

var shape: String = "circle"
var radius: float = 0.0
var length: float = 0.0
var width: float = 0.0
var seconds: float = 0.0
var damage: float = 0.0
var progress: float = 0.0
var done: bool = false
var _roster: Roster
var _material: ShaderMaterial
var _direction: Vector3 = Vector3.FORWARD
var _age: float = 0.0


static func circle(roster: Roster, at: Vector3, size: float, wind_up: float, hurt: float) -> Telegraph:
	var telegraph := Telegraph.new()
	telegraph.radius = size
	telegraph._begin(roster, at, wind_up, hurt, Vector2.ONE * size * 2.0)
	return telegraph


static func line(roster: Roster, from: Vector3, direction: Vector3, long: float, wide: float, wind_up: float,
		hurt: float) -> Telegraph:
	var telegraph := Telegraph.new()
	telegraph.shape = "line"
	telegraph.length = long
	telegraph.width = wide
	telegraph._direction = Vector3(direction.x, 0.0, direction.z).normalized()
	telegraph._begin(roster, from, wind_up, hurt, Vector2(wide, long))
	return telegraph


func _begin(roster: Roster, at: Vector3, wind_up: float, hurt: float, size: Vector2) -> void:
	name = "Telegraph"
	_roster = roster
	seconds = wind_up
	damage = hurt
	var plane := PlaneMesh.new()
	plane.size = size
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("shape", 0 if shape == "circle" else 1)
	var look: Dictionary = Tuning.doc("vfx")["combat"]["telegraph"]
	_material.set_shader_parameter("rim_color", Tuning.color(look["rim"]))
	_material.set_shader_parameter("fill_color", Tuning.color(look["fill"]))
	_material.set_shader_parameter("energy", float(look["energy"]))
	plane.material = _material
	var mesh := MeshInstance3D.new()
	mesh.mesh = plane
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	roster.add_effect(self, Vector3(at.x, _roster.ground_at(at) + LIFT, at.z))
	if shape == "line":
		basis = Basis.looking_at(_direction, Vector3.UP)
		mesh.position.z = -length * 0.5
		mesh.rotation.y = PI
	roster.warn_at(global_position)


## True when a ground point is inside the danger area.
func contains(point: Vector3) -> bool:
	var flat := Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
	if shape == "circle":
		return flat.length() <= radius
	var along: float = flat.dot(_direction)
	var side: float = absf(flat.dot(_direction.cross(Vector3.UP)))
	return along >= 0.0 and along <= length and side <= width * 0.5


## Called off before it lands (its caster was staggered or the fight ended).
func cancel() -> void:
	if done:
		return
	done = true
	finished.emit()
	queue_free()


func _process(delta: float) -> void:
	_age += delta
	if done:
		_material.set_shader_parameter("flash", maxf(1.0 - (_age - seconds) / FLASH_SECONDS, 0.0))
		return
	progress = minf(_age / seconds, 1.0)
	_material.set_shader_parameter("progress", progress)
	if _age >= seconds:
		_land()


func _land() -> void:
	done = true
	var player_in: bool = contains(_roster.player.global_position)
	if player_in:
		_roster.hurt_player(damage, _age, true)
	else:
		_roster.log_warning(_age)
	_roster.land_effect(self)
	resolved.emit(player_in)
	finished.emit()
	get_tree().create_timer(FLASH_SECONDS, false).timeout.connect(queue_free)
