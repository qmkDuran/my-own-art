class_name MachineDeath
extends Node2D
## A machine blowing apart: the one death every trash machine shares. A white-hot flash, an
## orange fireball, sparks, a few scrap chunks tumbling under gravity, a short puff of smoke
## and, when it was beaten, flecks of its stolen Glimra light bursting out (the XP itself
## flies out as the machine's LightDrop motes).
##
## Drawn in code on whole pixels, with a fixed, small number of bits. Event-only: spawned by
## the machine, it frees itself after DURATION.

const DURATION := 0.42
const FLASH_TIME := 0.05
const FIREBALL_TIME := 0.28
const SMOKE_START := 0.08
## How many of each bit (kept small: a pack can blow up at once).
const SPARK_COUNT := 12
const FIREBALL_BITS := 10
const SCRAP_COUNT := 4
const SMOKE_PUFFS := 3
const LIGHT_FLECKS := 8
## Pulls scrap and sparks down, in pixels per second squared.
const GRAVITY := 300.0
## Hottest to coolest, for the fireball bits.
const FIRE_COLORS: Array[Color] = [
	ApolloPalette.WHITE, ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.ORANGE_DARK, ApolloPalette.RED_LIGHT,
]
const SPARK_COLORS: Array[Color] = [ApolloPalette.WHITE, ApolloPalette.GOLD]
const SCRAP_COLORS: Array[Color] = [ApolloPalette.GREY, ApolloPalette.STONE_LIGHT, ApolloPalette.STONE]
const SMOKE_COLOR := ApolloPalette.STONE
const SMOKE_ALPHA := 0.7

## How big the blast is, in pixels: about the machine's half-width.
var _size: float = 10.0
var _light_color: Color = ApolloPalette.SKY_LIGHT
var _age: float = 0.0
var _sparks: Array[FlyingBit] = []
var _fire: Array[FlyingBit] = []
var _scrap: Array[FlyingBit] = []
var _flecks: Array[FlyingBit] = []
var _smoke_offsets: Array[Vector2] = []


## A bit of the blast flying out from the centre.
class FlyingBit:
	var position: Vector2
	var velocity: Vector2
	var color: Color
	var size: float
	var falls: bool

	func _init(start: Vector2, start_velocity: Vector2, bit_color: Color, bit_size: float, does_fall: bool) -> void:
		position = start
		velocity = start_velocity
		color = bit_color
		size = bit_size
		falls = does_fall

	func move(delta: float) -> void:
		if falls:
			velocity.y += MachineDeath.GRAVITY * delta
		position += velocity * delta


## Adds a blast to `world` centred on `at`. `size` is about the machine's half-width;
## `light_color` is the stolen light in its eye or core, which bursts out when `frees_light`.
static func spawn(world: Node, at: Vector2, size: float, light_color: Color, frees_light: bool) -> MachineDeath:
	var blast := MachineDeath.new()
	blast._size = size
	blast._light_color = light_color
	blast.z_index = 2
	blast._scatter_bits(frees_light)
	world.add_child(blast)
	blast.global_position = at.round()
	return blast


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	for group: Array[FlyingBit] in [_sparks, _fire, _scrap, _flecks]:
		for bit in group:
			bit.move(delta)
	queue_redraw()


func _draw() -> void:
	var progress := _age / DURATION
	_draw_smoke()
	_draw_fireball()
	if _age < FLASH_TIME:
		draw_circle(Vector2.ZERO, _size * 1.3, ApolloPalette.WHITE)
	_draw_bits(_fire, FIREBALL_TIME, true)
	_draw_bits(_sparks, DURATION * 0.7, false)
	_draw_bits(_flecks, DURATION, false)
	_draw_scrap(progress)


func _scatter_bits(frees_light: bool) -> void:
	var speed := _size * 11.0
	for index in SPARK_COUNT:
		var direction := Vector2.from_angle(TAU * index / SPARK_COUNT + randf_range(-0.2, 0.2))
		_sparks.append(FlyingBit.new(Vector2.ZERO, direction * speed * randf_range(0.8, 1.4), SPARK_COLORS[index % 2], 2.0 - index % 2, true))
	for index in FIREBALL_BITS:
		var direction := Vector2.from_angle(randf() * TAU)
		_fire.append(FlyingBit.new(direction * _size * 0.3, direction * speed * randf_range(0.25, 0.5), FIRE_COLORS[0], 2.0, false))
	for index in SCRAP_COUNT:
		var upward := Vector2.from_angle(randf_range(-PI * 0.9, -PI * 0.1))
		_scrap.append(FlyingBit.new(Vector2.ZERO, upward * speed * randf_range(0.6, 1.0), SCRAP_COLORS[index % SCRAP_COLORS.size()], 2.0, true))
	if frees_light:
		for index in LIGHT_FLECKS:
			var direction := Vector2.from_angle(TAU * index / LIGHT_FLECKS)
			var color := ApolloPalette.WHITE if index % 3 == 0 else _light_color
			_flecks.append(FlyingBit.new(Vector2.ZERO, direction * speed * 0.7, color, 1.0, false))
	for index in SMOKE_PUFFS:
		_smoke_offsets.append(Vector2(randf_range(-0.5, 0.5), randf_range(-0.6, 0.0)) * _size)


## A ball of fire that swells fast and burns down from white to orange.
func _draw_fireball() -> void:
	if _age >= FIREBALL_TIME:
		return
	var life := _age / FIREBALL_TIME
	var radius := _size * (0.6 + 0.6 * ease(life, 0.3)) * (1.0 - life * 0.5)
	draw_circle(Vector2.ZERO, roundf(radius), _fire_color(life + 0.4))
	draw_circle(Vector2.ZERO, roundf(radius * 0.65), _fire_color(life + 0.1))
	draw_circle(Vector2.ZERO, roundf(radius * 0.3), _fire_color(life))


## A few grey puffs that rise and spread while they thin out.
func _draw_smoke() -> void:
	if _age < SMOKE_START:
		return
	var life := (_age - SMOKE_START) / (DURATION - SMOKE_START)
	var color := Color(SMOKE_COLOR, SMOKE_ALPHA * (1.0 - life))
	for offset in _smoke_offsets:
		var at := (offset + Vector2(0, -_size * 0.8 * life)).round()
		draw_circle(at, roundf(_size * (0.35 + 0.35 * life)), color)


## Bits that shrink away over `lifetime`; fire bits also cool down.
func _draw_bits(bits: Array[FlyingBit], lifetime: float, cools: bool) -> void:
	var life := _age / lifetime
	if life >= 1.0:
		return
	for bit in bits:
		var color := _fire_color(life) if cools else bit.color
		var size := maxf(1.0, roundf(bit.size * (1.0 - life * 0.5)))
		draw_rect(Rect2(bit.position.round(), Vector2(size, size)), color)


## Tumbling chunks of plating: 2x2 with a darker pixel that flips over as they spin.
func _draw_scrap(progress: float) -> void:
	for index in _scrap.size():
		var chunk := _scrap[index]
		var corner := chunk.position.round()
		draw_rect(Rect2(corner, Vector2(2, 2)), chunk.color)
		var spin := int(progress * 12.0 + index) % 2
		draw_rect(Rect2(corner + Vector2(spin, 1 - spin), Vector2.ONE), ApolloPalette.OUTLINE)


func _fire_color(life: float) -> Color:
	var index := clampi(floori(life * FIRE_COLORS.size()), 0, FIRE_COLORS.size() - 1)
	return FIRE_COLORS[index]
