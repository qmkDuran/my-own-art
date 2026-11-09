class_name GaleCone
extends Node2D
## A blast of wind fanning out in a cone (Zephoot's Gale Push and Updraft Dash): a few
## streaks rush outward and fade. Added to the world, so it stays where it was blown.

const DURATION := 0.28
const STREAK_COUNT := 5
const STREAK_LENGTH := 9.0

var _direction: Vector2 = Vector2.RIGHT
var _reach: float = 40.0
var _cone_degrees: float = 70.0
var _age: float = 0.0


## Adds a gust to `world` at `at`, blowing toward `direction`.
static func spawn(world: Node, at: Vector2, direction: Vector2, reach: float, cone_degrees: float) -> void:
	var gust := GaleCone.new()
	gust._direction = direction.normalized()
	gust._reach = reach
	gust._cone_degrees = cone_degrees
	gust.z_index = 2
	world.add_child(gust)
	gust.global_position = at


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := _age / DURATION
	var half_cone := deg_to_rad(_cone_degrees) / 2.0
	var fade := 1.0 - progress
	for streak in STREAK_COUNT:
		var share := float(streak) / float(STREAK_COUNT - 1) if STREAK_COUNT > 1 else 0.5
		var heading := _direction.rotated(lerpf(-half_cone, half_cone, share))
		var tip := heading * _reach * (0.3 + 0.7 * progress)
		var tail := tip - heading * STREAK_LENGTH
		var color := ApolloPalette.WHITE if streak % 2 == 0 else ApolloPalette.SKY_LIGHT
		draw_line(tail.round(), tip.round(), Color(color, fade), 1.0)
	var arc_radius := _reach * (0.3 + 0.7 * progress)
	draw_arc(Vector2.ZERO, arc_radius, _direction.angle() - half_cone, _direction.angle() + half_cone, 12, Color(ApolloPalette.SKY, fade), 1.0)
