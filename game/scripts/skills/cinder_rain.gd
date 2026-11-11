class_name CinderRain
extends Skill
## Cinders fall over a chosen place (each warned by a small circle), each a small sunfire burst. Guided aims them
## at enemies inside; Lingering leaves fire; Last Cinder ends the rain with one great one.

const METEOR_PCT: float = 400.0
const METEOR_SCALE: float = 2.5


func radius() -> float:
	return float(data["radius"]) * (1.0 + val("area_pct") / 100.0) * p.stats.area_mult()


func use(target: Vector2) -> void:
	var at: Vector2 = p.global_position + (target - p.global_position).limit_length(float(data["range"]))
	var n: int = int(data["count"]) + int(val("count"))
	var spread: float = float(data["spread_time"])
	for k: int in n:
		var spot: Vector2 = _spot(at)
		_cinder(spot, spread * k / n, float(data["blast"]), 100.0)
	if rank("meteor") > 0:
		_cinder(at, spread + 0.2, float(data["blast"]) * METEOR_SCALE, METEOR_PCT)
	Audio.sfx("moths", -8.0, 0.6)


func _spot(at: Vector2) -> Vector2:
	if rank("guided") > 0:
		var foes: Array[Enemy] = enemies_in_arc(at, Vector2.RIGHT, radius(), 360.0)
		if not foes.is_empty():
			return foes[randi() % foes.size()].global_position
	return at + Vector2.RIGHT.rotated(randf() * TAU) * randf() * radius()


func _cinder(spot: Vector2, delay: float, blast: float, pct: float) -> void:
	var tg: Telegraph = Telegraph.circle(fx(), spot, blast, delay + 0.35)
	tg.col = Pal.c("amber")
	tg.fired.connect(func() -> void:
		Fx.burst(fx(), spot, 10, Vector2(40, 120), 0.35, [Pal.c("sun"), Pal.c("flame"), Pal.c("ember", 0.0)])
		Fx.flash(fx(), spot, blast * 2.5, Pal.c("flame"), 1.0, 0.2)
		Audio.sfx("hit", -12.0, 0.7)
		hit_area(spot, blast, pct)
		if val("linger") > 0.0:
			var b: Vector2 = base_range(25.0)
			BurningGround.spawn(fx(), spot, blast, val("linger"), (b.x + b.y) * 0.5, self))


func info() -> Array:
	var r: Vector2 = shown_range()
	return [["%d cinders, %d-%d each, over %d px" % [int(data["count"]) + int(val("count")), r.x, r.y, roundi(radius())], UiDraw.TEXT]]
