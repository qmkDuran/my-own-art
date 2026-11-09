class_name EmberHopLanding
extends Node2D
## Where an Ember Hop lands: a white flash on the ground, then a ring of fire rolling out
## flat along the ground with flame tongues licking up off it, cooling from white-hot
## through gold and orange to red (EmberooFlameColors' burst ramp), over a faint glow, with
## embers thrown up. Sized for the ~46 px hero; code-drawn on the world grid.
##
## FireTrail spawns it when the hop stops laying fire. It frees itself when done.

const DURATION := 0.4
## On the ground layer (z 0, drawn after it) and under the creatures (z 1).
const GROUND_Z_INDEX := 0
const FLASH_SECONDS := 0.035
## The flash: a flat white disc this many pixels across (half that tall).
const FLASH_RADIUS := 9.0
## The ring: radius from start to end, thickness from start to end, in pixels.
const RING_RADIUS := Vector2(6.0, 26.0)
const RING_THICKNESS := Vector2(4.0, 1.0)
## Flame tongues standing up off the ring: how many, how tall at most, how often they flicker.
const TONGUE_COUNT := 14
const TONGUE_HEIGHT := 6.0
const FLICKER_RATE := 20.0
## The ring breaks up into flickering pixels after this share of its life.
const BREAK_UP_START := 0.55
const GLOW_RADIUS := 24.0
const GLOW_STRENGTH := 0.3
## Embers thrown up off the ring: how many, how long they live, how fast.
const EMBER_COUNT := 12
const EMBER_LIFETIME := 0.6
const EMBER_SPEED := Vector2(30.0, 70.0)
const EMBER_GRAVITY := Vector2(0, -30)

var _ramp: Array[Color] = EmberooFlameColors.burst_ramp()
var _age: float = 0.0


## Adds a landing burst to `world` at `ground_position`.
static func spawn(world: Node, ground_position: Vector2) -> void:
	var landing := EmberHopLanding.new()
	world.add_child(landing)
	landing.global_position = ground_position.round()


func _ready() -> void:
	# Flat on the ground, under the creatures standing in it (like FireTrail).
	z_index = GROUND_Z_INDEX
	FxGlow.add_to(self, GLOW_RADIUS, _ramp[2], GLOW_STRENGTH, DURATION)
	_spawn_embers()


func _process(delta: float) -> void:
	_age += delta
	if _age >= maxf(DURATION, EMBER_LIFETIME):
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if _age >= DURATION:
		return
	if _age < FLASH_SECONDS:
		FxPixels.draw_ring(self, Vector2.ZERO, FLASH_RADIUS, 0.0, ApolloPalette.WHITE, FxPixels.GROUND_SQUASH)
		return
	var progress := _age / DURATION
	var radius := lerpf(RING_RADIUS.x, RING_RADIUS.y, ease(progress, 0.35))
	var thickness := lerpf(RING_THICKNESS.x, RING_THICKNESS.y, progress)
	var flicker_step := floori(_age * FLICKER_RATE)
	_draw_ring_pixels(radius, thickness, progress, flicker_step)
	_draw_tongues(radius, progress, flicker_step)


## The ring, pixel by pixel so it can break up: hotter on its leading (outer) edge.
func _draw_ring_pixels(radius: float, thickness: float, progress: float, flicker_step: int) -> void:
	var break_up := maxf(0.0, (progress - BREAK_UP_START) / (1.0 - BREAK_UP_START))
	var rows := ceili(radius * FxPixels.GROUND_SQUASH)
	var columns := ceili(radius)
	for y in range(-rows, rows):
		for x in range(-columns, columns):
			var flat := Vector2(x + 0.5, (y + 0.5) / FxPixels.GROUND_SQUASH)
			var inside := radius - flat.length()
			if inside < 0.0 or inside > thickness:
				continue
			if FxPixels.noise(x, y, flicker_step) < break_up:
				continue
			var heat_lost := progress * 0.75 + inside / maxf(thickness, 1.0) * 0.3
			draw_rect(Rect2(x, y, 1, 1), FxPixels.ramp_color(_ramp, heat_lost))


## Short flames standing up round the ring, re-rolled every flicker.
func _draw_tongues(radius: float, progress: float, flicker_step: int) -> void:
	for tongue in TONGUE_COUNT:
		var angle := TAU * (tongue + 0.5) / TONGUE_COUNT
		var foot := Vector2(cos(angle) * radius, sin(angle) * radius * FxPixels.GROUND_SQUASH).round()
		var height := roundi(TONGUE_HEIGHT * (1.0 - progress) * (0.4 + 0.6 * FxPixels.noise(tongue, 0, flicker_step)))
		for rise in height:
			var heat_lost := progress * 0.6 + float(rise) / TONGUE_HEIGHT * 0.5
			draw_rect(Rect2(foot + Vector2(0, -rise), Vector2.ONE), FxPixels.ramp_color(_ramp, heat_lost))


func _spawn_embers() -> void:
	var embers := CPUParticles2D.new()
	embers.one_shot = true
	embers.explosiveness = 0.9
	embers.amount = EMBER_COUNT
	embers.lifetime = EMBER_LIFETIME
	embers.local_coords = false
	embers.direction = Vector2.UP
	embers.spread = 70.0
	embers.initial_velocity_min = EMBER_SPEED.x
	embers.initial_velocity_max = EMBER_SPEED.y
	embers.gravity = EMBER_GRAVITY
	embers.damping_min = 40.0
	embers.damping_max = 70.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = RING_RADIUS.x
	embers.scale_amount_min = 1.0
	embers.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([_ramp[1], _ramp[2], _ramp[4], Color(_ramp[5], 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	embers.color_ramp = ramp
	# Embers rise in front of what stands on the ring.
	embers.z_index = 3
	embers.z_as_relative = false
	add_child(embers)
	embers.emitting = true
