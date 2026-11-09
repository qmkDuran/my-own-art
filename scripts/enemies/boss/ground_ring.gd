@abstract
class_name GroundRing
extends Node2D
## A ring rolling outward along the ground from a boss's slam (the Captain's ShockRing, the
## Shalendrill's QuakeRing). It hurts the player once as it passes their feet and shoves
## them outward, unless they dodge-hop over it (invulnerable) or stand where the ring is safe
## (`_is_safe_at`). Plays once and removes itself.

## How far past the band's edge the player's feet still count as on it, in pixels.
const HIT_SLACK := 2.0
## By the end of its travel the ring has lost this share of its full strength.
const END_FADE := 0.6

var max_radius: float = 96.0
## Seconds the ring takes to reach `max_radius`.
var travel_time: float = 0.9
## How thick the ring is, in pixels; the player is hit while it overlaps their feet.
var band_width: float = 5.0
var damage: int = 2
var push_speed: float = 180.0
var push_time: float = 0.25
var color: Color = ApolloPalette.RED_LIGHT
var edge_color: Color = ApolloPalette.ORANGE
## How sharply it slows as it spreads: 1 is a steady speed, higher starts faster.
var slowing_power: float = 1.5

var _elapsed: float = 0.0
var _has_hit: bool = false


## Puts `ring` into `world` at `at` (world coordinates), on the ground: over the floor,
## under the creatures (z 1).
static func place(ring: GroundRing, world: Node, at: Vector2) -> void:
	ring.z_index = 0
	world.add_child(ring)
	ring.global_position = at


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= travel_time:
		queue_free()
		return
	_try_to_hit_player()
	queue_redraw()


func _draw() -> void:
	_draw_ring(_radius(), 1.0 - END_FADE * (_elapsed / travel_time))


## Starts fast and slows as it spreads, like a real shockwave.
func _radius() -> float:
	var progress := _elapsed / travel_time
	return max_radius * (1.0 - pow(1.0 - progress, slowing_power))


func _try_to_hit_player() -> void:
	var player := PlayerFinder.find(self)
	if _has_hit or player == null:
		return
	var from_centre := player.global_position - global_position
	if absf(from_centre.length() - _radius()) > band_width / 2.0 + HIT_SLACK:
		return
	if _is_safe_at(from_centre):
		return
	if not PlayerHit.try_to_hurt(player, damage, global_position):
		return  # hopped over it
	_has_hit = true
	PlayerHit.shove(player, from_centre.normalized() * push_speed, push_time)


## True when a player this far from the centre is in a safe spot of the ring (e.g. its gap).
@abstract func _is_safe_at(from_centre: Vector2) -> bool


## Draws the ring at `radius`, `fade` (1 down to 1 - END_FADE) times its full strength.
@abstract func _draw_ring(radius: float, fade: float) -> void
