class_name CanalFish
extends Node3D
## Softly glowing fish swimming in the canal: little teal, amber and lilac shapes that drift up and down its
## length just under the glassy surface, wiggling as they go and turning at the ends.

const BODY_STRETCH: Vector3 = Vector3(0.45, 0.3, 1.0)
const TAIL_SHARE: float = 0.45
const TURN_MARGIN: float = 1.5
const LANE_MARGIN: float = 0.8
const WIGGLE_ANGLE: float = 0.35
const HALO_SIZE: float = 3.0
const HALO_STRENGTH: float = 0.25
const FIN_THICKNESS: float = 0.02
const TAIL_OFFSET: float = 0.6

var _fish: Array[Node3D] = []
var _speeds: Array[float] = []
var _lanes: Array[float] = []
var _clock: float = 0.0
var _canal: Dictionary
var _x_range: Vector2


func build() -> void:
	name = "CanalFish"
	_canal = Tuning.doc("town")["canal"]
	var spec: Dictionary = Tuning.doc("town")["fish"]
	_x_range = Vector2(float(spec["x_range"][0]), float(spec["x_range"][1]))
	var colours: Array = spec["colors"]
	for index: int in int(spec["count"]):
		var colour: Color = Tuning.color(colours[index % colours.size()])
		var fish: Node3D = _one(colour, float(spec["size"]), float(spec["energy"]))
		add_child(fish)
		var lane: float = randf_range(float(_canal["z0"]) + LANE_MARGIN, float(_canal["z1"]) - LANE_MARGIN)
		fish.position = Vector3(randf_range(_x_range.x, _x_range.y), float(_canal["water_y"]) +
			float(spec["depth"]), lane)
		fish.rotation.y = PI * 0.5 if randf() < 0.5 else -PI * 0.5
		_fish.append(fish)
		_speeds.append(randf_range(float(spec["speed_min"]), float(spec["speed_max"])))
		_lanes.append(lane)


func _process(delta: float) -> void:
	_clock += delta
	var wiggle: float = Tuning.number("town", "fish", "wiggle")
	for index: int in _fish.size():
		var fish: Node3D = _fish[index]
		var heading: float = -fish.global_basis.z.x
		fish.position.x += heading * _speeds[index] * delta
		fish.position.z = _lanes[index] + sin(_clock * _speeds[index] + index) * LANE_MARGIN * 0.5
		if fish.position.x < _x_range.x + TURN_MARGIN or fish.position.x > _x_range.y - TURN_MARGIN:
			fish.rotation.y = -PI * 0.5 if fish.position.x < _x_range.x + TURN_MARGIN else PI * 0.5
		(fish.get_child(0) as Node3D).rotation.y = sin(_clock * wiggle + index) * WIGGLE_ANGLE


## One fish, lying flat on the water like a koi seen from above: a soft glowing oval body, a tail, and a wide
## faint halo on the surface around it.
func _one(colour: Color, size: float, energy: float) -> Node3D:
	var fish := Node3D.new()
	var body := Node3D.new()
	fish.add_child(body)
	body.add_child(_flat_glow(colour * energy, Vector2(size * BODY_STRETCH.x, size), Vector3.ZERO))
	body.add_child(_flat_glow(colour * energy, Vector2(size * TAIL_SHARE, size * TAIL_SHARE), Vector3(0.0, 0.0,
		size * TAIL_OFFSET)))
	fish.add_child(_flat_glow(colour * energy * HALO_STRENGTH, Vector2.ONE * size * HALO_SIZE, Vector3.DOWN *
		FIN_THICKNESS))
	return fish


func _flat_glow(colour: Color, size: Vector2, at: Vector3) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = size
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = colour
	material.albedo_texture = ParticleKit.soft_dot()
	plane.material = material
	var glow := MeshInstance3D.new()
	glow.mesh = plane
	glow.position = at
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return glow
