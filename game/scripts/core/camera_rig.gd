class_name CameraRig
extends Camera2D
## Follows the Lamplighter smoothly within the map, and shakes on impact (trauma decays; shake = trauma^2 so small
## hits barely move it). The screen_shake setting scales it (0 = off).

const SMOOTH: float = 8.0
const MAX_OFFSET: float = 9.0
const DECAY: float = 2.2
const FREQ: float = 30.0

static var instance: CameraRig

var trauma: float = 0.0
var target: Node2D
var _noise := FastNoiseLite.new()
var _t: float = 0.0


func setup(follow: Node2D, map_size: Vector2, top: float) -> void:
	instance = self
	target = follow
	limit_left = 0
	limit_top = int(top)
	limit_right = int(map_size.x)
	limit_bottom = int(map_size.y)
	position_smoothing_enabled = true
	position_smoothing_speed = SMOOTH
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	global_position = follow.global_position
	reset_smoothing()


static func shake(amount: float) -> void:
	if instance != null:
		instance.trauma = minf(1.0, instance.trauma + amount * float(GameData.setting("screen_shake", 1.0)))


func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		global_position = target.global_position + Vector2(0, -16)
	_t += delta
	trauma = maxf(0.0, trauma - DECAY * delta)
	var k: float = trauma * trauma * MAX_OFFSET
	offset = Vector2(_noise.get_noise_2d(_t * FREQ, 0.0), _noise.get_noise_2d(0.0, _t * FREQ)) * k * 2.0
