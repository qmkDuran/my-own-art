class_name Flock
extends Node3D
## A few birds wheeling slowly in a wide circle high over the canopy, wings flapping.

const FLAP_RATE: float = 9.0
const FLAP_SHARE: float = 0.6
const SPACING: float = 0.35
const BOB: float = 0.6

var _birds: Array[Node3D] = []
var _radius: float = 1.0
var _speed: float = 1.0
var _time: float = 0.0


func setup(centre: Vector3, count: int, radius: float, speed: float, size: Vector3) -> void:
	name = "Flock"
	position = centre
	_radius = radius
	_speed = speed
	var wing := PrismMesh.new()
	wing.size = size
	for k: int in count:
		var bird := MeshInstance3D.new()
		bird.mesh = wing
		bird.material_override = WoodsMaterials.solid("bird")
		bird.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(bird)
		_birds.append(bird)


func _process(delta: float) -> void:
	_time += delta
	for k: int in _birds.size():
		var angle: float = _time * _speed + k * SPACING
		var bird: Node3D = _birds[k]
		bird.position = Vector3(cos(angle) * _radius, sin(_time + k) * BOB, sin(angle) * _radius)
		bird.rotation.y = -angle
		bird.scale.y = 1.0 + sin(_time * FLAP_RATE + k) * FLAP_SHARE
