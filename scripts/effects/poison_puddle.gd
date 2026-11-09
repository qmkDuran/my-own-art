class_name PoisonPuddle
extends Node2D
## Toxlop's poison puddle (PoisonPuddleToss): a glob of goo arcs to the landing spot, splats
## into a flat puddle, and every `seconds_between_doses` poisons each enemy standing in it.
## Fades out at the end of its life, then removes itself.

## Seconds the glob takes to fly to the landing spot.
const FLIGHT_SECONDS := 0.22
## How high the glob's arc peaks, in pixels.
const ARC_HEIGHT := 12.0
## Seconds the puddle takes to fade out at the end.
const FADE_SECONDS := 0.5
## The puddle is a flat ellipse: this much as tall as it is wide.
const FLATNESS := 0.4
const GLOB_RADIUS := 2.0

@export var seconds_between_doses: float = 0.5
@export var poison_per_tick: int = 1
@export var seconds_between_ticks: float = 1.0
@export var poison_seconds: float = 2.0

var radius: float = 16.0
var lifetime: float = 4.0

var _flight_from: Vector2
var _landing: Vector2
var _age: float = 0.0
var _dose_left: float = 0.0
var _has_landed: bool = false


## Adds a puddle to `world`, thrown from `from` to `landing` (world coordinates).
static func spawn(world: Node, from: Vector2, landing: Vector2, puddle_radius: float, seconds: float) -> void:
	var puddle := PoisonPuddle.new()
	puddle.radius = puddle_radius
	puddle.lifetime = seconds
	puddle._flight_from = from
	puddle._landing = landing
	world.add_child(puddle)
	puddle.global_position = landing


func _ready() -> void:
	z_index = 0


func _physics_process(delta: float) -> void:
	_age += delta
	if not _has_landed:
		if _age >= FLIGHT_SECONDS:
			_has_landed = true
			_age = 0.0
			_splat()
	else:
		_dose_left -= delta
		if _dose_left <= 0.0:
			_dose_left = seconds_between_doses
			_poison_enemies_inside()
		modulate.a = clampf((lifetime - _age) / FADE_SECONDS, 0.0, 1.0)
		if _age >= lifetime:
			queue_free()
	queue_redraw()


func _poison_enemies_inside() -> void:
	for target_health in AbilityTargets.within(self, global_position, radius):
		Poisoned.apply_to(target_health, poison_per_tick, seconds_between_ticks, poison_seconds)


func _splat() -> void:
	var splat := preload("res://scenes/effects/toxic_splat.tscn").instantiate() as ToxicSplat
	get_parent().add_child(splat)
	splat.global_position = global_position
	splat.play()


func _draw() -> void:
	if not _has_landed:
		var progress := _age / FLIGHT_SECONDS
		var glob := _flight_from.lerp(_landing, progress) + Vector2(0, -sin(PI * progress) * ARC_HEIGHT)
		draw_circle(to_local(glob), GLOB_RADIUS, ApolloPalette.GREEN_LIGHT)
		return
	var spread := clampf(_age / 0.12, 0.0, 1.0)
	var size := Vector2(radius * 2.0, radius * 2.0 * FLATNESS) * (0.5 + 0.5 * spread)
	_draw_ellipse(Vector2.ZERO, size, ApolloPalette.GREEN)
	_draw_ellipse(Vector2(-1, -0.5), size * 0.6, ApolloPalette.GREEN_LIGHT)
	var bubble := Vector2(sin(_age * 5.0) * radius * 0.4, -1.0).round()
	draw_circle(bubble, 1.0, ApolloPalette.LIME_PALE)


func _draw_ellipse(centre: Vector2, size: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for step in 20:
		var angle := TAU * step / 20.0
		points.append(centre + Vector2(cos(angle) * size.x / 2.0, sin(angle) * size.y / 2.0))
	draw_colored_polygon(points, color)
