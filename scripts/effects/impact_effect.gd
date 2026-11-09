class_name ImpactEffect
extends Node2D
## A jab landing (and the burst when Emberoo leaps into a zone): a white flash at the fist
## for a frame or two, then spark rays fanning out along the punch with a shock ring and a
## white-hot core, all cooling through gold and orange to red (EmberooFlameColors'
## burst ramp) before they break up, over a faint additive glow and a few falling sparks.
## Jabs alternate fists, so impacts alternate too: a straight punch streak, then a curved
## hook smear. Sized for the ~46 px hero (HeroFxScale), code-drawn on the world grid.
##
## Whoever spawns it sets `rotation` toward the hit (it is drawn facing right). It reads
## that once, then draws unrotated so every pixel stays on the grid. Frees itself when done.

const DURATION := 0.24
## The white flash: how long, and its star's arm length in pixels.
const FLASH_SECONDS := 0.035
const FLASH_STAR_ARM := 11
## The white-hot core at the fist: starting radius, and the share of the life it lasts.
const CORE_RADIUS := 5.0
const CORE_SHARE := 0.5
## Spark rays: how many, how wide the fan is either side of the punch, how long (shortest,
## longest, in pixels), and the share of the life they spend shooting out.
const RAY_COUNT := 6
const RAY_HALF_SPREAD := deg_to_rad(75.0)
const RAY_LENGTH := Vector2(11.0, 22.0)
const RAY_GROW_SHARE := 0.4
## Rays are 2 pixels thick for this share of the life, then thin to 1.
const THICK_SHARE := 0.35
## Rays and the ring break up into flickering pixels after this share of the life.
const BREAK_UP_START := 0.6
## The shock ring: radius from start to end, and the share of the life it shows.
const RING_RADIUS := Vector2(6.0, 15.0)
const RING_SHARE := 0.7
## The smears: the straight streak's length behind the fist; the hook smear's radius, half
## arc and how far behind the fist its centre sits; and the share of the life they show.
const STREAK_LENGTH := 12.0
const HOOK_RADIUS := 10.0
const HOOK_HALF_ARC := deg_to_rad(80.0)
const HOOK_CENTRE_BACK := 5.0
const SMEAR_SHARE := 0.45
## The glow behind it all.
const GLOW_RADIUS := 12.0
const GLOW_STRENGTH := 0.3
## Falling sparks: how many, how long they live, speed range and the pull down.
const SPARK_COUNT := 6
const SPARK_LIFETIME := 0.4
const SPARK_SPEED := Vector2(50.0, 110.0)
const SPARK_SPREAD_DEGREES := 55.0
const SPARK_GRAVITY := Vector2(0, 220)
const SPARK_DAMPING := 60.0
const IMPACT_Z_INDEX := 2

## Which smear the next impact draws (the fists take turns).
static var _next_is_hook: bool = false

var _direction: Vector2 = Vector2.RIGHT
var _is_hook: bool = false
var _ramp: Array[Color] = EmberooFlameColors.burst_ramp()
var _ray_angles := PackedFloat32Array()
var _ray_lengths := PackedFloat32Array()
var _age: float = 0.0
var _started: bool = false


func _ready() -> void:
	# Deferred: the spawner sets the rotation right after adding it.
	_start.call_deferred()


func _process(delta: float) -> void:
	if not _started:
		return
	_age += delta
	if _age >= maxf(DURATION, SPARK_LIFETIME):
		queue_free()
		return
	queue_redraw()


func _start() -> void:
	_direction = Vector2.from_angle(rotation)
	rotation = 0.0
	global_position = global_position.round()
	z_index = IMPACT_Z_INDEX
	_is_hook = _next_is_hook
	_next_is_hook = not _next_is_hook
	for ray in RAY_COUNT:
		var spread := lerpf(-RAY_HALF_SPREAD, RAY_HALF_SPREAD, (ray + randf_range(0.2, 0.8)) / RAY_COUNT)
		_ray_angles.append(_direction.angle() + spread)
		# Rays straight along the punch shoot furthest.
		var along := 1.0 - absf(spread) / RAY_HALF_SPREAD
		_ray_lengths.append(lerpf(RAY_LENGTH.x, RAY_LENGTH.y, along * randf_range(0.7, 1.0)))
	FxGlow.add_to(self, GLOW_RADIUS, _ramp[2], GLOW_STRENGTH, DURATION)
	_spawn_sparks()
	_started = true


func _draw() -> void:
	if not _started or _age >= DURATION:
		return
	var progress := _age / DURATION
	if _age < FLASH_SECONDS:
		_draw_smear(0.0, ApolloPalette.WHITE)
		FxPixels.draw_disc(self, Vector2.ZERO, CORE_RADIUS + 1.0, ApolloPalette.WHITE)
		FxPixels.draw_star(self, Vector2.ZERO, FLASH_STAR_ARM, ApolloPalette.WHITE)
		return
	if progress < SMEAR_SHARE:
		_draw_smear(progress / SMEAR_SHARE, FxPixels.ramp_color(_ramp, 0.2 + progress))
	if progress < RING_SHARE:
		_draw_shock_ring(progress / RING_SHARE)
	_draw_rays(progress)
	if progress < CORE_SHARE:
		var core_progress := progress / CORE_SHARE
		FxPixels.draw_disc(self, Vector2.ZERO, CORE_RADIUS * (1.0 - core_progress), FxPixels.ramp_color(_ramp, core_progress * 0.6))


## The straight punch streak behind the fist, or the curved hook smear; `progress` 0..1 eats
## it away from its far end.
func _draw_smear(progress: float, color: Color) -> void:
	var thickness := 3 if progress < 0.5 else 2
	if not _is_hook:
		var back := _direction * -STREAK_LENGTH * (1.0 - progress)
		FxPixels.draw_thick_line(self, back, Vector2.ZERO, thickness, color)
		return
	var centre := -_direction * HOOK_CENTRE_BACK
	var steps := ceili(HOOK_RADIUS * HOOK_HALF_ARC * 2.0)
	for step in steps + 1:
		var along := float(step) / steps
		if along < progress:
			continue
		var angle := _direction.angle() + lerpf(HOOK_HALF_ARC, -HOOK_HALF_ARC, along)
		var at := (centre + Vector2.from_angle(angle) * HOOK_RADIUS).round()
		draw_rect(Rect2(at, Vector2.ONE * thickness), color)


func _draw_shock_ring(progress: float) -> void:
	var radius := lerpf(RING_RADIUS.x, RING_RADIUS.y, ease(progress, 0.4))
	var thickness := 2.0 if progress < 0.4 else 1.0
	FxPixels.draw_ring(self, Vector2.ZERO, radius, radius - thickness, FxPixels.ramp_color(_ramp, 0.25 + progress * 0.75))


func _draw_rays(progress: float) -> void:
	var grow := ease(minf(1.0, progress / RAY_GROW_SHARE), 0.3)
	var thickness := 2 if progress < THICK_SHARE else 1
	var break_up := maxf(0.0, (progress - BREAK_UP_START) / (1.0 - BREAK_UP_START))
	for ray in _ray_angles.size():
		var ray_direction := Vector2.from_angle(_ray_angles[ray])
		var head := _ray_lengths[ray] * grow
		var tail := maxf(CORE_RADIUS, _ray_lengths[ray] * maxf(0.0, progress - 0.15) * 1.1)
		for distance in range(floori(tail), ceili(head)):
			if FxPixels.noise(ray, distance, floori(_age * 30.0)) < break_up:
				continue
			# Hottest (and thickest) at the head; everything cools with time.
			var behind_head := (head - distance) / maxf(head - tail, 1.0)
			var heat_lost := progress * 0.8 + behind_head * 0.4
			var at := (ray_direction * distance).round()
			var size := thickness if behind_head < 0.35 else 1
			draw_rect(Rect2(at, Vector2.ONE * size), FxPixels.ramp_color(_ramp, heat_lost))


## A handful of sparks thrown out along the punch that arc down and fade.
func _spawn_sparks() -> void:
	var sparks := CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = SPARK_COUNT
	sparks.lifetime = SPARK_LIFETIME
	sparks.local_coords = false
	sparks.direction = _direction
	sparks.spread = SPARK_SPREAD_DEGREES
	sparks.initial_velocity_min = SPARK_SPEED.x
	sparks.initial_velocity_max = SPARK_SPEED.y
	sparks.gravity = SPARK_GRAVITY
	sparks.damping_min = SPARK_DAMPING
	sparks.damping_max = SPARK_DAMPING
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([_ramp[0], _ramp[1], _ramp[3], Color(_ramp[5], 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.65, 1.0])
	sparks.color_ramp = ramp
	add_child(sparks)
	sparks.emitting = true
