class_name ShockRing
extends Node2D
## The Captain's slam shockwave: a thick ring that rolls outward along the ground with one
## gap in it, the gap's edges marked in gold like the slam's telegraph. It hurts the player
## once as it passes over them, unless they stand in the gap or dodge-hop over it
## (invulnerable). Plays once and removes itself.

var max_radius: float = 96.0
## Seconds the ring takes to reach `max_radius`.
var travel_time: float = 0.9
## Direction (radians) the gap faces, and its width.
var gap_angle: float = 0.0
var gap_width: float = deg_to_rad(50.0)
## How thick the ring is, in pixels; the player is hit while it overlaps their feet.
var band_width: float = 5.0
var damage: int = 2
var push_speed: float = 180.0
var push_time: float = 0.25
var color: Color = ApolloPalette.RED_LIGHT
var edge_color: Color = ApolloPalette.ORANGE

var _elapsed: float = 0.0
var _has_hit: bool = false


## Adds a ring to `world` at `at` (world coordinates) and sets it rolling.
static func spawn(world: Node, at: Vector2, gap_facing: float) -> ShockRing:
	var ring := ShockRing.new()
	ring.gap_angle = gap_facing
	ring.z_index = 0
	world.add_child(ring)
	ring.global_position = at
	return ring


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= travel_time:
		queue_free()
		return
	_try_to_hit_player()
	queue_redraw()


func _radius() -> float:
	# Starts fast and slows a little as it spreads, like a real shockwave.
	var progress := _elapsed / travel_time
	return max_radius * (1.0 - pow(1.0 - progress, 1.6))


func _try_to_hit_player() -> void:
	var player := PlayerFinder.find(self)
	if _has_hit or player == null:
		return
	var from_centre := player.global_position - global_position
	if absf(from_centre.length() - _radius()) > band_width / 2.0 + 2.0:
		return
	if absf(angle_difference(from_centre.angle(), gap_angle)) <= gap_width / 2.0:
		return  # standing in the gap
	if not PlayerHit.try_to_hurt(player, damage, global_position):
		return  # hopped over it
	_has_hit = true
	PlayerHit.shove(player, from_centre.normalized() * push_speed, push_time)


func _draw() -> void:
	var fade := 1.0 - 0.6 * (_elapsed / travel_time)
	var radius := _radius()
	var from := gap_angle + gap_width / 2.0
	var to := gap_angle + TAU - gap_width / 2.0
	draw_arc(Vector2.ZERO, radius, from, to, 48, Color(color, 0.85 * fade), band_width)
	draw_arc(Vector2.ZERO, radius + band_width / 2.0, from, to, 48, Color(edge_color, fade), 1.0)
	TelegraphPainter.draw_gap_marks(self, Vector2.ZERO, radius, gap_angle, gap_width, fade)
