class_name QuakeSlam
extends BossAttack
## The Shalendrill's quake slam (the dodge check): it heaves both fists overhead while the
## ground shows the quake's full reach (a faint red disc and a pulsing ring, with the wave's
## front-to-be growing toward it), then pounds the ground: a QuakeRing rolls out with no gap,
## so the player has to dodge-leap over it (or be beyond its reach). In phase 2 a second ring
## follows. Afterwards its fists are stuck in the ground for a long moment: the best punish
## window of the fight, and the spot a hop over the ring lands you in (Ember Hop's trail
## burns it there). Drawn on the ground, under every creature (z_index in the scene).

const FILL_ALPHA := Vector2(0.06, 0.18)
const RING_ALPHA := Vector2(0.55, 0.85)
## Its fists land this far either side of its feet (a dust puff under each), in pixels.
const FIST_SPREAD := 8.0
## The screen shake with each ring.
const SHAKE_STRENGTH := 2.5
const SHAKE_SECONDS := 0.3

@export var trigger_distance: float = 100.0
@export var ring_radius: float = 104.0
@export var ring_travel_time: float = 1.0
@export var damage: int = 2
## Rings per slam in phase 1 and phase 2.
@export var rings_per_phase: Vector2i = Vector2i(1, 2)
## Seconds between one ring and the next (longer than a dodge and its cooldown, so both can be leapt).
@export var ring_interval: float = 0.9
@export var screen_shake: ScreenShake
@export var dust_scene: PackedScene

var _wind_up_progress: float = 0.0
var _rings_sent: int = 0


func _is_wanted(distance_to_player: float) -> bool:
	return distance_to_player <= trigger_distance


func _on_start() -> void:
	_wind_up_progress = 0.0
	_rings_sent = 0
	follow_through = ring_interval * (_ring_count() - 1) + 0.3


func _on_wind_up(progress: float) -> void:
	_wind_up_progress = progress


func update(seconds_attacking: float) -> void:
	super.update(seconds_attacking)
	if is_winding_up() or _rings_sent >= _ring_count():
		return
	if seconds_attacking - current_wind_up >= ring_interval * _rings_sent:
		_send_ring()


func _release() -> void:
	_send_ring()


func _send_ring() -> void:
	_rings_sent += 1
	var ring := QuakeRing.spawn(boss.get_parent(), boss.global_position)
	ring.max_radius = ring_radius
	ring.travel_time = ring_travel_time
	ring.damage = damage
	for fist_x: float in [-FIST_SPREAD, FIST_SPREAD]:
		DustPuff.spawn(dust_scene, boss.get_parent(), boss.global_position + Vector2(fist_x, 0))
	if screen_shake != null:
		screen_shake.shake(SHAKE_STRENGTH, SHAKE_SECONDS)


func _ring_count() -> int:
	return rings_per_phase.y if is_phase_two else rings_per_phase.x


func _draw() -> void:
	if not is_winding_up() or _wind_up_progress <= 0.0:
		return
	var pulse := TelegraphPainter.pulse(_wind_up_progress * current_wind_up)
	var fill := Color(TelegraphPainter.DANGER_COLOR, lerpf(FILL_ALPHA.x, FILL_ALPHA.y, _wind_up_progress))
	draw_circle(Vector2.ZERO, ring_radius, fill)
	var ring_alpha := lerpf(RING_ALPHA.x, RING_ALPHA.y, _wind_up_progress)
	var ring_color := TelegraphPainter.outline_color(pulse, ring_alpha)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 64, ring_color, TelegraphPainter.OUTLINE_WIDTH)
	draw_arc(Vector2.ZERO, ring_radius * _wind_up_progress, 0.0, TAU, 48, Color(ring_color, ring_alpha * 0.5), 1.0)
