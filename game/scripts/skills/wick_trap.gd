class_name WickTrap
extends Skill
## Lit wicks set in the ground (up to three; more with More Wicks). Each arms after a moment and bursts when an
## enemy comes near. Big Bang, Bright Wick (Light), Chain (bursts set off nearby traps), Snare (stuns).

var traps: Array[TrapFx] = []


func max_traps() -> int:
	return int(data["max"]) + int(val("max"))


func radius() -> float:
	return float(data["radius"]) * (1.0 + val("area_pct") / 100.0) * p.stats.area_mult()


func use(target: Vector2) -> void:
	traps = traps.filter(func(t: TrapFx) -> bool: return is_instance_valid(t))
	if traps.size() >= max_traps():
		traps.pop_front().queue_free()
	var at: Vector2 = Game.current.layout.free_spot_near(p.global_position + (target - p.global_position).limit_length(float(data["range"])), 4.0)
	var t: TrapFx = TrapFx.spawn(fx(), at, self)
	traps.append(t)
	Audio.sfx("lantern_catch", -10.0, 1.4)


func burst(t: TrapFx) -> void:
	var at: Vector2 = t.global_position
	traps.erase(t)
	t.queue_free()
	Fx.burst(fx(), at, 18, Vector2(60, 180), 0.45, [Pal.c("sun"), Pal.c("flame"), Pal.c("ember", 0.0)])
	Fx.flash(fx(), at, radius() * 2.0, Pal.c("flame"), 1.3, 0.25)
	Audio.sfx("flare", -8.0, 1.3)
	CameraRig.shake(0.12)
	hit_area(at, radius(), 100.0 + val("damage_pct"), {"stun": val("stun"), "knockback": 40.0})
	p.light.add(val("light"))
	if rank("chain") > 0:
		for o: TrapFx in traps.duplicate():
			if is_instance_valid(o) and o.global_position.distance_to(at) < radius():
				o.trip()


func info() -> Array:
	var r: Vector2 = shown_range(100.0 + val("damage_pct"))
	return [["Up to %d wicks, %d-%d in %d px" % [max_traps(), r.x, r.y, roundi(radius())], UiDraw.TEXT]]
