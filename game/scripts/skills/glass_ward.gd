class_name GlassWard
extends Skill
## A barrier of glass worth a share of your life. Hits drain it first; when it breaks or its time runs out it
## bursts outward. Mirror shatters enemy shots that touch you while it holds; Rewall grows a second, smaller ward.

var amount: float = 0.0
var _t: float = 0.0
var _second: bool = false


func up() -> bool:
	return amount > 0.0


func cooldown() -> float:
	return maxf(1.0, super() - val("cd"))


func use(_target: Vector2) -> void:
	_raise(1.0)
	_second = false
	Audio.sfx("lantern_catch", -4.0, 0.6)


func _raise(strength: float) -> void:
	amount = p.stats.max_life() * (float(data["barrier_pct"]) + val("barrier_pct")) / 100.0 * strength
	_t = float(data["duration"])
	Fx.halo(fx(), p.global_position + Vector2(0, -24), 40.0, Pal.c("glint", 0.7), 0.3)


## Takes as much of a hit as it can; returns what is left for life.
func absorb(dmg: float) -> float:
	if not up():
		return dmg
	var taken: float = minf(amount, dmg)
	amount -= taken
	if amount <= 0.0:
		_burst()
	return dmg - taken


func tick(delta: float) -> void:
	if not up():
		return
	_t -= delta
	if _t <= 0.0:
		amount = 0.0
		_burst()


func _burst() -> void:
	var at: Vector2 = p.global_position
	Fx.burst(fx(), at + Vector2(0, -20), 30, Vector2(80, 220), 0.5, [Pal.c("glint"), Pal.c("glass_lt"), Pal.c("glass", 0.0)], Vector2.UP, 180.0, Vector2(1, 2))
	Audio.sfx("die_glass", -4.0, 1.2)
	hit_area(at, float(data["burst_radius"]) * p.stats.area_mult(), 100.0 + val("burst_pct"), {"knockback": 50.0})
	if rank("rewall") > 0 and not _second:
		_second = true
		_raise(0.5)


func info() -> Array:
	var r: Vector2 = shown_range(100.0 + val("burst_pct"))
	return [["Barrier: %d (%.0f%% of life) for %.0f s" % [roundi(p.stats.max_life() * (float(data["barrier_pct"]) + val("barrier_pct")) / 100.0),
		float(data["barrier_pct"]) + val("barrier_pct"), float(data["duration"])], UiDraw.TEXT], ["Burst: %d-%d" % [r.x, r.y], UiDraw.TEXT]]
