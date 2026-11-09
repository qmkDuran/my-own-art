class_name QuakeRing
extends Node2D
## A ring of cracking ground rolling out from the Shalendrill's slam. Unlike the Captain's
## ShockRing it has no gap: the only way through is a dodge (invulnerable mid-leap) or
## staying beyond its reach. It hurts the player once as it passes their feet. Plays once
## and removes itself.

var max_radius: float = 104.0
## Seconds the ring takes to reach `max_radius`.
var travel_time: float = 1.0
## How thick the band is, in pixels.
var band_width: float = 6.0
var damage: int = 2
var push_speed: float = 160.0
var push_time: float = 0.2
var color: Color = ApolloPalette.RED_LIGHT
var rubble_color: Color = ApolloPalette.STONE_LIGHT
var edge_color: Color = ApolloPalette.ORANGE

## Rubble specks along the band, one every this many radians.
const RUBBLE_STEP := 0.21
## How far past the band's edge the player's feet still count as on it, in pixels.
const HIT_SLACK := 2.0

var _elapsed: float = 0.0
var _has_hit: bool = false


## Adds a ring to `world` at `at` (world coordinates) and sets it rolling.
static func spawn(world: Node, at: Vector2) -> QuakeRing:
	var ring := QuakeRing.new()
	# On the ground: over the floor, under the creatures (z 1).
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


## Fast at first, slowing as it spreads.
func _radius() -> float:
	var progress := _elapsed / travel_time
	return max_radius * (1.0 - pow(1.0 - progress, 1.5))


func _try_to_hit_player() -> void:
	var player := PlayerFinder.find(self)
	if _has_hit or player == null:
		return
	var from_centre := player.global_position - global_position
	if absf(from_centre.length() - _radius()) > band_width / 2.0 + HIT_SLACK:
		return
	if not PlayerHit.try_to_hurt(player, damage, global_position):
		return  # leapt over it
	_has_hit = true
	PlayerHit.shove(player, from_centre.normalized() * push_speed, push_time)


func _draw() -> void:
	var fade := 1.0 - 0.6 * (_elapsed / travel_time)
	var radius := _radius()
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color, 0.8 * fade), band_width)
	draw_arc(Vector2.ZERO, radius + band_width / 2.0, 0.0, TAU, 64, Color(edge_color, fade), 1.0)
	# Bits of broken ground thrown up along the band.
	var angle := fmod(radius * 0.05, RUBBLE_STEP)
	while angle < TAU:
		var spot := (Vector2.from_angle(angle) * (radius - 1.0)).floor()
		draw_rect(Rect2(spot, Vector2(2, 1)), Color(rubble_color, fade))
		angle += RUBBLE_STEP
