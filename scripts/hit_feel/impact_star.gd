class_name ImpactStar
extends Node2D
## The hit spark: a star of short rays bursting out from where a hit landed, in the
## element's colour with a small white sparkle (a pixel plus) at its heart, gone in about 3
## frames. Drawn on the pixel grid. No filled squares: a hit-stop freezes the spark, and a
## block of white over an enemy reads as a rendering bug.

## Seconds the star shows (about 3 frames at 60 fps).
const LIFETIME := 0.06
const RAY_COUNT := 8
## The white sparkle's arms are at most this many pixels long.
const MAX_SPARKLE_ARM := 2
## The rays start at half the radius and grow to all of it; their inner ends fly out to
## this share of it. Every other ray is this much shorter.
const START_RADIUS_SHARE := 0.5
const INNER_RADIUS_SHARE := 0.6
const SHORT_RAY_SHARE := 0.6
## The sparkle's arms, as a share of the radius (shrinking to nothing over the star's life).
const SPARKLE_ARM_SHARE := 0.15
## Over sprays and effects.
const STAR_Z_INDEX := 4

var _radius: float = 8.0
var _color: Color = ApolloPalette.WHITE
var _age: float = 0.0
var _ray_angles: Array[float] = []


static func spawn(world: Node, at: Vector2, radius: float, color: Color) -> void:
	var star := ImpactStar.new()
	star._radius = radius
	star._color = color
	star.z_index = STAR_Z_INDEX
	world.add_child(star)
	star.global_position = at.round()


func _ready() -> void:
	var twist := randf() * TAU / RAY_COUNT
	for ray in RAY_COUNT:
		_ray_angles.append(twist + TAU * ray / RAY_COUNT)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := _age / LIFETIME
	var outer := _radius * (START_RADIUS_SHARE + (1.0 - START_RADIUS_SHARE) * progress)
	var inner := _radius * INNER_RADIUS_SHARE * progress
	for ray in RAY_COUNT:
		var direction := Vector2.from_angle(_ray_angles[ray])
		var length := outer if ray % 2 == 0 else outer * SHORT_RAY_SHARE
		draw_line((direction * inner).round(), (direction * length).round(), _color, 1.0)
	_draw_sparkle(clampi(roundi(_radius * SPARKLE_ARM_SHARE * (1.0 - progress)), 0, MAX_SPARKLE_ARM))


## A white pixel plus with arms `arm` pixels long (just the centre pixel for 0).
func _draw_sparkle(arm: int) -> void:
	draw_rect(Rect2(Vector2(-arm, 0), Vector2(arm * 2 + 1, 1)), ApolloPalette.WHITE)
	draw_rect(Rect2(Vector2(0, -arm), Vector2(1, arm * 2 + 1)), ApolloPalette.WHITE)
