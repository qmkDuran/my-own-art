class_name CameraRig
extends Camera2D
## Follows the Lamplighter smoothly within the map, and shakes on impact (trauma decays; shake = trauma^2 so small
## hits barely move it). The screen_shake setting scales it (0 = off).

const SMOOTH: float = 8.0
const MAX_OFFSET: float = 9.0
const DECAY: float = 2.2
const FREQ: float = 30.0
const BOSS_LEAN: float = 0.45
const MAX_LEAN: float = 180.0
const FRAME_FADE: float = 0.4

static var instance: CameraRig

var trauma: float = 0.0
var target: Node2D
var frames: Array = []                 ## [point, radius, weight]: landmarks the view leans toward when near
var focus: Node2D                      ## a boss: the view frames you and it together
var _intro_t: float = 0.0
var _intro_at: Vector2
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


## How far the view leans from the Lamplighter toward a boss or a nearby landmark.
func _lean() -> Vector2:
	var me: Vector2 = target.global_position
	if is_instance_valid(focus) and not (focus as Enemy).dead:
		var mid: Vector2 = focus.global_position + Vector2(0, -(focus as Enemy).body_height() * 0.6)
		return ((mid - me) * BOSS_LEAN).limit_length(MAX_LEAN)
	for f: Array in frames:                  # a landmark: frame it and you together (the midpoint, fading out at range)
		var d: float = me.distance_to(f[0])
		var near: float = clampf((float(f[1]) - d) / (float(f[1]) * FRAME_FADE), 0.0, 1.0)
		if near > 0.0:
			return ((f[0] as Vector2) - me) * 0.5 * float(f[2]) * near
	return Vector2.ZERO


static func shake(amount: float) -> void:
	if instance != null:
		instance.trauma = minf(1.0, instance.trauma + amount * float(GameData.setting("screen_shake", 1.0)))


## Arrival shot: start on a landmark, hold, then glide to the Lamplighter.
func intro(at: Vector2, seconds: float) -> void:
	_intro_at = at
	_intro_t = seconds
	global_position = at
	reset_smoothing()


func _physics_process(delta: float) -> void:
	_intro_t -= delta
	if _intro_t > 0.0:
		global_position = _intro_at
	elif is_instance_valid(target):
		global_position = target.global_position + Vector2(0, -16) + _lean()
	_t += delta
	trauma = maxf(0.0, trauma - DECAY * delta)
	var k: float = trauma * trauma * MAX_OFFSET
	offset = Vector2(_noise.get_noise_2d(_t * FREQ, 0.0), _noise.get_noise_2d(0.0, _t * FREQ)) * k * 2.0
