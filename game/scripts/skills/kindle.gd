class_name Kindle
extends Skill
## A buff: for a while every hit you land carries added sunfire and may ignite; Warm Hands quickens you, Ember
## Skin burns whoever hits you, Wildfire spreads burns from burning deaths.

const WILDFIRE_RADIUS: float = 60.0
const HEARTH_MULT: float = 2.0

var _t: float = 0.0


func active() -> bool:
	return _t > 0.0


func duration() -> float:
	return (float(data["duration"]) + val("duration")) * (HEARTH_MULT if p.stats.has_special("hearth") else 1.0)


func use(_target: Vector2) -> void:
	_t = duration()
	Fx.halo(fx(), p.global_position + Vector2(0, -24), 50.0, Pal.c("flame", 0.8), 0.4)
	Audio.sfx("flare", -8.0, 1.5)


func tick(delta: float) -> void:
	_t = maxf(0.0, _t - delta)
	if active() and randf() < delta * 6.0:
		Fx.burst(fx(), p.global_position + Vector2(randf_range(-8, 8), -30), 1, Vector2(10, 30), 0.5, [Pal.c("gold"), Pal.c("ember", 0.0)], Vector2.UP, 20.0)


## Added sunfire per hit while kindled (already includes Stoke).
func added() -> float:
	if not active():
		return 0.0
	var b: Vector2 = base_range()
	return (b.x + b.y) * 0.5 * (1.0 + val("added_pct") / 100.0)


func burn_chance() -> float:
	return float(data["burn_chance"]) if active() else 0.0


func haste() -> float:
	return 1.0 + val("speed_pct") / 100.0 if active() else 1.0


func struck_by(e: Enemy) -> void:
	if active() and rank("ember_skin") > 0 and is_instance_valid(e):
		e.ignite(added() * 2.0)


func on_kill(e: Enemy) -> void:
	if active() and rank("wildfire") > 0 and e.burning():
		for o: Enemy in enemies_in_arc(e.global_position, Vector2.RIGHT, WILDFIRE_RADIUS, 360.0):
			o.ignite(added() * 2.0)


func info() -> Array:
	return [["Lasts %.0f s: +%d sunfire per hit, +%d%% ignite chance" % [duration(), roundi(added() if active() else (base_range().x + base_range().y) * 0.5 * (1.0 + val("added_pct") / 100.0)),
		roundi(float(data["burn_chance"]))], UiDraw.TEXT]]
