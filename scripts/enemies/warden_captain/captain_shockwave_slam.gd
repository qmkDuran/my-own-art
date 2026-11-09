class_name CaptainShockwaveSlam
extends BossAttack
## The Captain's shockwave slam, a bigger Warden slam: he raises the halberd-rod overhead while
## red energy gathers into it, and the ground shows what's coming (see TelegraphPainter): a
## faint red danger zone as far as the wave will roll, a bold pulsing ring at its edge, and
## the safe gap left clear, marked with gold end-caps. Then he slams it down: a ShockRing rolls
## outward. Stand in the gap or dodge-hop over the ring. Afterwards he stays bent over his rod
## for a moment (punish him). Drawn on the ground, under every creature (z_index in the scene).

## The danger zone's fill, faint at the start of the wind-up and a little stronger by the slam.
const FILL_ALPHA := Vector2(0.08, 0.2)
## The ring's opacity at the start and end of the wind-up, and how much the pulse adds.
const RING_ALPHA := Vector2(0.55, 0.85)
const RING_PULSE_ALPHA := 0.15
## The screen shake as the rod hits the ground.
const SHAKE_STRENGTH := 2.0
const SHAKE_SECONDS := 0.25

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
	if player != null and player.global_position != boss.global_position:
		toward_player = boss.global_position.direction_to(player.global_position)
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
	var ring := ShockRing.spawn(boss.get_parent(), boss.global_position + slam_point, _gap_angle)
	ring.max_radius = ring_radius
	ring.travel_time = ring_travel_time
	ring.gap_width = deg_to_rad(gap_degrees)
	ring.damage = damage
	DustPuff.spawn(dust_scene, boss.get_parent(), boss.global_position)
	if screen_shake != null:
		screen_shake.shake(SHAKE_STRENGTH, SHAKE_SECONDS)


func _on_finish() -> void:
	if charge_particles != null:
		charge_particles.stop_charging()


func _draw() -> void:
	if not is_winding_up() or _wind_up_progress <= 0.0:
		return
	var gap := deg_to_rad(gap_degrees)
	var pulse := TelegraphPainter.pulse(_wind_up_progress * current_wind_up)
	var fill := Color(TelegraphPainter.DANGER_COLOR, lerpf(FILL_ALPHA.x, FILL_ALPHA.y, _wind_up_progress))
	TelegraphPainter.fill_wedge(self, slam_point, ring_radius, _gap_angle + gap / 2.0, _gap_angle + TAU - gap / 2.0, fill)
	var ring_alpha := lerpf(RING_ALPHA.x, RING_ALPHA.y, _wind_up_progress) + RING_PULSE_ALPHA * pulse
	var ring_color := TelegraphPainter.outline_color(pulse, ring_alpha)
	TelegraphPainter.draw_gapped_ring(self, slam_point, ring_radius, _gap_angle, gap, ring_color, TelegraphPainter.OUTLINE_WIDTH)
	TelegraphPainter.draw_gap_marks(self, slam_point, ring_radius, _gap_angle, gap, ring_alpha)
	# The wave's front-to-be grows toward the ring as the slam gets closer.
	TelegraphPainter.draw_gapped_ring(self, slam_point, ring_radius * _wind_up_progress, _gap_angle, gap, Color(ring_color, ring_alpha * 0.5), 1.0)
