class_name CritFlare
extends Node2D
## A critical hit landing on an enemy: a white four-pointed star flash for a frame or two,
## then the star shrinks through gold while a ring snaps out round the body, cooling to
## red (EmberooFlameColors' burst ramp), over a faint glow and a spray of sparks.
## A Counter Punch's crit is bigger: a second ring and speed lines bursting outward.
## Code-drawn on the world grid; CritFlares spawns it, and it frees itself when done.

const DURATION := 0.28
const FLASH_SECONDS := 0.035
## The star's arm length in pixels (plain crit, Counter Punch).
const STAR_ARM := Vector2i(13, 19)
## Share of the life the star takes to shrink away.
const STAR_SHARE := 0.6
## The ring's radius from start to end (plain crit, then Counter Punch).
const RING_RADII: Array[Vector2] = [Vector2(5.0, 20.0), Vector2(7.0, 30.0)]
## The Counter Punch's second ring starts this much later.
const SECOND_RING_DELAY := 0.25
## The Counter Punch's speed lines: how many, how long, and how far out they travel.
const SPOKE_COUNT := 8
const SPOKE_LENGTH := 7.0
const SPOKE_TRAVEL := Vector2(6.0, 30.0)
const GLOW_RADIUS := Vector2(18.0, 26.0)
const GLOW_STRENGTH := 0.32
const SPARK_COUNT := Vector2i(7, 12)
const SPARK_LIFETIME := 0.45
const FLARE_Z_INDEX := 3

var _is_counter: bool = false
var _ramp: Array[Color] = EmberooFlameColors.burst_ramp()
var _age: float = 0.0


## Adds a flare to `world` at `at` (the struck body's middle); bigger for a Counter Punch.
static func spawn(world: Node, at: Vector2, is_counter: bool) -> CritFlare:
	var flare := CritFlare.new()
	flare._is_counter = is_counter
	world.add_child(flare)
	flare.global_position = at.round()
	return flare


func _ready() -> void:
	z_index = FLARE_Z_INDEX
	var size_index := 1 if _is_counter else 0
	FxGlow.add_to(self, GLOW_RADIUS[size_index], _ramp[1], GLOW_STRENGTH, DURATION)
	_spawn_sparks(SPARK_COUNT[size_index])


func _process(delta: float) -> void:
	_age += delta
	if _age >= maxf(DURATION, SPARK_LIFETIME):
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if _age >= DURATION:
		return
	var size_index := 1 if _is_counter else 0
	var arm := STAR_ARM[size_index]
	if _age < FLASH_SECONDS:
		FxPixels.draw_disc(self, Vector2.ZERO, 4.0, ApolloPalette.WHITE)
		FxPixels.draw_star(self, Vector2.ZERO, arm, ApolloPalette.WHITE)
		return
	var progress := _age / DURATION
	_draw_ring(RING_RADII[size_index], progress)
	if _is_counter:
		_draw_ring(RING_RADII[size_index], (progress - SECOND_RING_DELAY) / (1.0 - SECOND_RING_DELAY))
		_draw_spokes(progress)
	if progress < STAR_SHARE:
		var star_progress := progress / STAR_SHARE
		var shrunk := roundi(arm * (1.0 - ease(star_progress, 0.5)))
		if shrunk > 0:
			FxPixels.draw_star(self, Vector2.ZERO, shrunk, FxPixels.ramp_color(_ramp, star_progress * 0.5))


func _draw_ring(radii: Vector2, progress: float) -> void:
	if progress <= 0.0 or progress >= 1.0:
		return
	var radius := lerpf(radii.x, radii.y, ease(progress, 0.35))
	var thickness := 2.0 if progress < 0.5 else 1.0
	FxPixels.draw_ring(self, Vector2.ZERO, radius, radius - thickness, FxPixels.ramp_color(_ramp, 0.15 + progress * 0.85))


## Speed lines shooting straight out between the star's arms.
func _draw_spokes(progress: float) -> void:
	var travelled := lerpf(SPOKE_TRAVEL.x, SPOKE_TRAVEL.y, ease(progress, 0.4))
	var length := SPOKE_LENGTH * (1.0 - progress)
	var color := FxPixels.ramp_color(_ramp, 0.1 + progress * 0.8)
	for spoke in SPOKE_COUNT:
		var outward := Vector2.from_angle(TAU * (spoke + 0.5) / SPOKE_COUNT)
		FxPixels.draw_thick_line(self, (outward * travelled).round(), (outward * (travelled + length)).round(), 1, color)


func _spawn_sparks(count: int) -> void:
	var sparks := CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = count
	sparks.lifetime = SPARK_LIFETIME
	sparks.local_coords = false
	sparks.spread = 180.0
	sparks.initial_velocity_min = 60.0
	sparks.initial_velocity_max = 130.0
	sparks.gravity = Vector2(0, 200)
	sparks.damping_min = 60.0
	sparks.damping_max = 90.0
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([_ramp[0], _ramp[1], _ramp[3], Color(_ramp[5], 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.65, 1.0])
	sparks.color_ramp = ramp
	add_child(sparks)
	sparks.emitting = true
