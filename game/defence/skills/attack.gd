class_name Attack
extends Node3D
## One piece of lantern magic that works on its own around the player. Its numbers come from data/skills.json
## (base + per_level for each level past the first), scaled by the passives. Attacks that fire on a timer
## override fire(); attacks that are always there (orbiting things) override tick().

var id: String = ""
var level: int = 1
var spec: Dictionary = {}
var player: Node3D
var horde: Horde
var magic: MagicStats
var _cooldown: float = 0.0


func setup(attack_id: String, attack_spec: Dictionary, owner_player: Node3D, creatures: Horde,
		stats: MagicStats) -> void:
	id = attack_id
	name = attack_id.to_pascal_case()
	spec = attack_spec
	player = owner_player
	horde = creatures
	magic = stats
	_cooldown = 0.0
	on_level_changed()


func max_level() -> int:
	return int(spec["max_level"])


func level_up() -> void:
	level = mini(level + 1, max_level())
	on_level_changed()


## A stat at the current level, before passives.
func stat(key: String) -> float:
	return float(spec["base"][key]) + float(spec["per_level"][key]) * (level - 1)


func area_stat(key: String) -> float:
	return stat(key) * magic.area_scale()


func colour() -> Color:
	return Tuning.color(spec["color"])


func _physics_process(delta: float) -> void:
	tick(delta)
	if not spec["base"].has("cooldown"):
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown = stat("cooldown") * magic.cooldown_scale()
		fire()


## Called every physics frame (orbiting attacks move and hit here).
func tick(_delta: float) -> void:
	pass


## Called each time the cooldown runs out.
func fire() -> void:
	pass


## Called when the level changes (attacks that build visible parts rebuild them).
func on_level_changed() -> void:
	pass


## A small glowing ball, the look shared by bolts, fireflies and flames.
func glow_ball(size: float, energy: float) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = size * 0.5
	sphere.height = size
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = colour()
	material.emission_enabled = true
	material.emission = colour()
	material.emission_energy_multiplier = energy
	sphere.material = material
	var mesh := MeshInstance3D.new()
	mesh.mesh = sphere
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh
