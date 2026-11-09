class_name CaptainShockwaveSlam
extends CaptainAttack
## The Captain's shockwave slam, a bigger Warden slam: he raises the halberd-rod overhead while
## red energy gathers into it, and a faint ring on the ground shows how far the wave will roll
## and where its gap is. Then he slams it down: a ShockRing rolls outward. Stand in the gap or
## dodge-hop over the ring. Afterwards he stays bent over his rod for a moment (punish him).

## He slams when the player is within this distance, in pixels.
@export var trigger_distance: float = 90.0
## How far the shockwave rolls, in pixels.
@export var ring_radius: float = 96.0
## Seconds the shockwave takes to roll out.
@export var ring_travel_time: float = 0.9
## Width of the gap in the ring, in degrees.
@export var gap_degrees: float = 55.0
## The gap faces this many degrees (at random, either side) away from the player, so they
## have to move to reach it.
@export var gap_offset_degrees: Vector2 = Vector2(50, 130)
@export var damage: int = 2
@export var telegraph_color: Color = ApolloPalette.RED
## Where the rod hits the ground, relative to his feet.
@export var slam_point: Vector2 = Vector2(0, -1)
@export var charge_particles: ChargeParticles
@export var screen_shake: ScreenShake
## Dust kicked up by the slam.
@export var dust_scene: PackedScene

var _gap_angle: float = 0.0
var _wind_up_progress: float = 0.0


func _is_wanted(distance_to_player: float) -> bool:
	return distance_to_player <= trigger_distance


func _on_start() -> void:
	var toward_player := Vector2.DOWN
	var player := PlayerFinder.find(self)
	if player != null and player.global_position != captain.global_position:
		toward_player = captain.global_position.direction_to(player.global_position)
	var offset := deg_to_rad(randf_range(gap_offset_degrees.x, gap_offset_degrees.y))
	_gap_angle = toward_player.angle() + offset * (1.0 if randf() < 0.5 else -1.0)
	_wind_up_progress = 0.0
	if charge_particles != null:
		charge_particles.start_charging()


func _on_wind_up(progress: float) -> void:
	_wind_up_progress = progress


func _release() -> void:
	if charge_particles != null:
		charge_particles.stop_charging()
	var ring := ShockRing.spawn(captain.get_parent(), captain.global_position + slam_point, _gap_angle)
	ring.max_radius = ring_radius
	ring.travel_time = ring_travel_time
	ring.gap_width = deg_to_rad(gap_degrees)
	ring.damage = damage
	DustPuff.spawn(dust_scene, captain.get_parent(), captain.global_position)
	if screen_shake != null:
		screen_shake.shake(2.0, 0.25)


func _on_finish() -> void:
	if charge_particles != null:
		charge_particles.stop_charging()


func _draw() -> void:
	if not is_winding_up() or _wind_up_progress <= 0.0:
		return
	# The ring to come, gap included, fading in as the slam gets closer.
	var gap := deg_to_rad(gap_degrees)
	var alpha := 0.3 + 0.5 * _wind_up_progress
	draw_arc(slam_point, ring_radius, _gap_angle + gap / 2.0, _gap_angle + TAU - gap / 2.0, 48, Color(telegraph_color, alpha), 1.0)
	draw_arc(slam_point, ring_radius * _wind_up_progress, 0.0, TAU, 32, Color(telegraph_color, alpha * 0.5), 1.0)
