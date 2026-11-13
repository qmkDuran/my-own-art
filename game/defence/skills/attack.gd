class_name Attack
extends Node3D
## One piece of lantern magic that works on its own around the player. Its numbers come from data/skills.json
## (base + per_level for each level past the first), scaled by the passives. Attacks that fire on a timer
## override fire(); attacks that are always there (orbiting things) override tick().

const SMALLEST: float = 0.01

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


## Shrinks and hides a glowing thing as it nears the camera, so magic passing close to the lens never blooms into
## a white smudge.
func fade_near_camera(node: Node3D) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var near: float = float(Tuning.doc("skills")["camera_fade"][0])
	var far: float = float(Tuning.doc("skills")["camera_fade"][1])
	var share: float = clampf((node.global_position.distance_to(camera.global_position) - near) / (far - near), 0.0,
		1.0)
	node.visible = share > 0.0
	node.scale = Vector3.ONE * maxf(share, SMALLEST)


## A small soft glow in the attack's colour, the look shared by bolts, fireflies and candle flames.
func glow_ball(size: float, energy: float) -> Node3D:
	return SoftGlow.make(colour(), size, energy)
