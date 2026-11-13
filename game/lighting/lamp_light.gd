class_name LampLight
extends OmniLight3D
## One warm light of the town: a street lamp, a wall lantern or a lit window. Reads its look from the matching
## section of data/lighting.json, flickers gently like a flame, and can be snuffed out and relit (the night's
## creatures snuff lamps; the player relights them). Lamps with a flame show a small glowing flame mesh that blooms.

const FADE_SPEED: float = 2.5
const MS_TO_SECONDS: float = 0.001
const SMALLEST_FLAME: float = 0.01

var kind: String = ""
var lit: bool = true
var _base_energy: float = 0.0
var _level: float = 1.0
var _phase: float = 0.0
var _flame: MeshInstance3D


func setup(lamp_kind: String) -> void:
	kind = lamp_kind
	name = lamp_kind.to_pascal_case()
	light_color = Tuning.look_color(kind, "color")
	_base_energy = Tuning.look_f(kind, "energy")
	light_energy = _base_energy
	omni_range = Tuning.look_f(kind, "range")
	omni_attenuation = Tuning.look_f(kind, "attenuation")
	light_volumetric_fog_energy = Tuning.look_f(kind, "fog_energy")
	distance_fade_enabled = true
	distance_fade_begin = Tuning.look_f("budget", "light_fade_begin")
	distance_fade_length = Tuning.look_f("budget", "light_fade_length")
	shadow_enabled = false
	_phase = randf() * TAU
	if Tuning.doc("lighting")[kind].has("flame_size"):
		_add_flame()


func _process(delta: float) -> void:
	_level = move_toward(_level, 1.0 if lit else 0.0, FADE_SPEED * delta)
	var time: float = Time.get_ticks_msec() * MS_TO_SECONDS
	var flicker: float = sin(time * Tuning.look_f("flicker", "speed") + _phase) * sin(time * PI + _phase * 2.0)
	light_energy = _base_energy * _level * (1.0 + flicker * Tuning.look_f("flicker", "amount"))
	if _flame != null:
		_flame.visible = _level > 0.0
		_flame.scale = Vector3.ONE * maxf(_level, SMALLEST_FLAME)


func _add_flame() -> void:
	var sphere := SphereMesh.new()
	var size: float = Tuning.look_f(kind, "flame_size")
	sphere.radius = size
	sphere.height = size * 2.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = light_color
	material.emission_enabled = true
	material.emission = light_color
	material.emission_energy_multiplier = Tuning.look_f(kind, "flame_energy")
	sphere.material = material
	_flame = MeshInstance3D.new()
	_flame.mesh = sphere
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_flame)
