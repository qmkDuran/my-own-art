class_name Crosshair
extends Control
## The centred crosshair: four short ticks around a small dot. The ticks spread while the heavy charges, a hit
## marker (four diagonal ticks) flashes on every hit (bigger and hotter on a kill), and a diamond marks a
## locked-on enemy where it is on screen.

const DOT: float = 1.5
const KILL_SCALE: float = 1.6
const DIAMOND: int = 4

var charge: float = 0.0
var lock_at: Vector2 = Vector2.INF
var _hit: float = 0.0
var _kill: bool = false


func flash_hit(killed: bool) -> void:
	_hit = Tuning.f("combat_hud", "hit_seconds")
	_kill = killed


func _process(delta: float) -> void:
	_hit = maxf(_hit - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var centre: Vector2 = size * 0.5
	var colour: Color = AbilitySlot.colour_of("crosshair")
	var gap: float = lerpf(Tuning.f("combat_hud", "crosshair_gap"), Tuning.f("combat_hud", "crosshair_charge_gap"),
		charge)
	var length: float = Tuning.f("combat_hud", "crosshair_length")
	var width: float = Tuning.f("combat_hud", "crosshair_width")
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(centre + direction * gap, centre + direction * (gap + length), colour, width, true)
	draw_circle(centre, DOT, colour)
	if _hit > 0.0:
		var hit_size: float = Tuning.f("combat_hud", "hit_size") * (KILL_SCALE if _kill else 1.0)
		var hit_colour: Color = AbilitySlot.colour_of("kill" if _kill else "hit")
		for direction: Vector2 in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
			var unit: Vector2 = direction.normalized()
			draw_line(centre + unit * gap, centre + unit * (gap + hit_size), hit_colour, width, true)
	if lock_at != Vector2.INF:
		var points := PackedVector2Array()
		var lock: float = Tuning.f("combat_hud", "lock_size")
		for index: int in DIAMOND + 1:
			points.append(lock_at - global_position + Vector2.from_angle(TAU * index / DIAMOND) * lock)
		draw_polyline(points, AbilitySlot.colour_of("lock"), width, true)
