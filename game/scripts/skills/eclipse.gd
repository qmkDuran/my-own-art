class_name Eclipse
extends Skill
## Shutter the lantern: for a few seconds every enemy is Shrouded (even in other lights), your light is an ember,
## and you hit the Shrouded far harder, move faster and drink life from your hits. When it ends the light bursts
## out around you. Tree: longer, more leech, speed, a bigger closing burst, Umbra (deaths burst into shadow),
## Pitch Dark (Flare and Lantern Toss cost nothing), New Moon (faster recovery; kills extend it).

const KILL_EXTEND: float = 1.0
const MAX_EXTEND: float = 4.0
const UMBRA_RADIUS: float = 60.0

var _t: float = 0.0
var _extended: float = 0.0


func active() -> bool:
	return _t > 0.0


func duration() -> float:
	return float(data["duration"]) + val("duration")


func cooldown() -> float:
	return super() / (1.0 + val("cdr_pct") / 100.0)


func vs_shrouded_pct() -> float:
	return float(data["vs_shrouded_pct"]) if active() else 0.0


func leech() -> float:
	return (float(data["leech_pct"]) + val("leech_pct")) / 100.0 if active() else 0.0


func move_mult() -> float:
	return 1.0 + (float(data["move_pct"]) + val("move_pct")) / 100.0 if active() else 1.0


func use(_target: Vector2) -> void:
	_t = duration()
	_extended = 0.0
	p.light.smother(_t)
	Game.current.shift_darkness(Game.current.darkness.darkened(0.6), _t - 0.3, 0.4)
	Fx.halo(fx(), p.global_position, 160.0, Pal.c("violet", 0.7), 0.5)
	Audio.sfx("boss_wind", -6.0, 1.6)
	EclipseAura.attach(p, self)


func tick(delta: float) -> void:
	if _t <= 0.0:
		return
	_t -= delta
	if _t <= 0.0:
		_unshutter()


## The shutter opens: light bursts out around you.
func _unshutter() -> void:
	var reach: float = float(data["burst_radius"]) * (1.0 + val("burst_reach") / 100.0) * p.stats.area_mult()
	var more: float = 1.0 + val("burst_more") / 100.0
	BurstFx.spawn(fx(), p.global_position + Vector2(0, -10), reach)
	Fx.flash(fx(), p.global_position, reach * 1.6, Pal.c("gold"), 1.8, 0.4)
	Audio.sfx("flare", -3.0, 0.8)
	CameraRig.shake(0.3)
	for e: Enemy in enemies_in_arc(p.global_position, Vector2.RIGHT, reach, 360.0):
		Combat.hit_enemy(e, roll(float(data["burst_pct"])), opts({"dir": e.global_position - p.global_position, "more": more, "knockback": 60.0}))


## A kill during Eclipse: Umbra bursts the body, New Moon stretches the dark.
func on_kill(e: Enemy) -> void:
	if not active():
		return
	if rank("umbra") > 0:
		Fx.burst(fx(), e.global_position, 16, Vector2(40, 120), 0.5, [Pal.c("violet_lt"), Pal.c("violet"), Pal.c("void", 0.0)])
		for o: Enemy in enemies_in_arc(e.global_position, Vector2.RIGHT, UMBRA_RADIUS, 360.0):
			Combat.hit_enemy(o, roll(val("umbra_pct")), opts({"dir": o.global_position - e.global_position}))
	if rank("new_moon") > 0 and _extended < MAX_EXTEND:
		_extended += KILL_EXTEND
		_t += KILL_EXTEND
		p.light.smother(_t)


func info() -> Array:
	var r: Vector2 = shown_range(float(data["burst_pct"]))
	return [["Lasts %.1f s: every enemy Shrouded, +%d%% damage to them" % [duration(), roundi(float(data["vs_shrouded_pct"]))], UiDraw.TEXT],
		["+%d%% speed, %d%% of damage returned as life" % [roundi(float(data["move_pct"]) + val("move_pct")),
			roundi(float(data["leech_pct"]) + val("leech_pct"))], UiDraw.TEXT],
		["Closing burst: %d-%d in %d px" % [r.x, r.y, roundi(float(data["burst_radius"]) * (1.0 + val("burst_reach") / 100.0))], UiDraw.TEXT]]
