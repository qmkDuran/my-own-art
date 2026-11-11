class_name Sunlash
extends Skill
## Whip of light, a three-beat combo: lash, backlash, crack (longer, narrower, heavier). Tree: speed, reach,
## ignite, Light on hit, strike behind too, bonus against Shrouded, and Sunwave crescents off the crack.

const COMBO_RESET: float = 1.2
const WAVE_SPEED: float = 380.0
const WAVE_LIFE: float = 0.55
const WAVE_FAN: float = 0.22
const CRESCENT: String = "res://art/fx/crescent.png"

var _beat: int = 0
var _last: float = -10.0


func cast_time() -> float:
	return float(data["time"]) / (speed_mult() * (1.0 + val("speed_pct") / 100.0))


func reach(crack: bool) -> float:
	return float(data["crack_range" if crack else "range"]) * (1.0 + val("range_pct") / 100.0)


func use(target: Vector2) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last > COMBO_RESET:
		_beat = 0
	_last = now
	var crack: bool = _beat == 2
	_beat = (_beat + 1) % 3
	var dir: Vector2 = (target - p.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = p.aim
	_strike(dir, crack, _beat == 2)
	if rank("backhand") > 0:
		_strike(-dir, crack, _beat != 2)
	if crack and rank("sunwave") > 0:
		_waves(dir)


func _strike(dir: Vector2, crack: bool, flip: bool) -> void:
	var arc: float = float(data["crack_arc_deg" if crack else "arc_deg"])
	var center: Vector2 = p.global_position + Vector2(0, -18)
	WhipFx.lash(fx(), center, p.lantern_pos(), dir, reach(crack), arc, flip, crack)
	Audio.sfx("crack" if crack else "lash", -5.0 if crack else -8.0, randf_range(0.95, 1.1))
	if crack:
		Fx.flash(fx(), center + dir * reach(crack), 90.0, Pal.c("gold"), 1.1, 0.18)
		CameraRig.shake(0.12)
	var mult: float = float(data["crack_mult"]) if crack else 1.0
	for e: Enemy in enemies_in_arc(p.global_position, dir, reach(crack), arc):
		_hit(e, dir, mult, crack)


func _hit(e: Enemy, dir: Vector2, mult: float, crack: bool) -> void:
	var burn: float = val("burn_chance")
	if p.stats.has_special("long_night") and e.shrouded:
		burn = 100.0
	Combat.hit_enemy(e, roll(float(data["damage_pct"])), opts({"dir": dir, "more": mult, "heavy": crack,
		"vs_shrouded_pct": val("vs_shrouded_pct"), "burn_chance": burn, "knockback": 40.0 if crack else 14.0}))
	p.light.add(val("light_per_hit"))


func _waves(dir: Vector2) -> void:
	var n: int = 1 + int(val("extra_waves"))
	for k: int in n:
		var d: Vector2 = dir.rotated((k - (n - 1) * 0.5) * WAVE_FAN)
		var pr: Projectile = Projectile.spawn(fx(), p.global_position + Vector2(0, -18), d * WAVE_SPEED, PropSprite.tex(CRESCENT),
			Pal.c("gold"), false, func(e: Node2D) -> void:
				Combat.hit_enemy(e as Enemy, roll(val("wave_pct")), opts({"dir": d})))
		pr.pierce = true
		pr.life = WAVE_LIFE
		pr.hit_radius = 18.0


func info() -> Array:
	var r: Vector2 = shown_range(float(data["damage_pct"]))
	var rows: Array = [["Damage: %d-%d sunfire (crack x%.1f)" % [r.x, r.y, float(data["crack_mult"])], UiDraw.TEXT],
		["Reach: %d px, crack %d px" % [roundi(reach(false)), roundi(reach(true))], UiDraw.TEXT],
		["Attack time: %.2f s" % cast_time(), UiDraw.TEXT]]
	if rank("sunwave") > 0:
		var w: Vector2 = shown_range(val("wave_pct"))
		rows.append(["Sunwave: %d crescent(s), %d-%d each" % [1 + int(val("extra_waves")), w.x, w.y], UiDraw.UP])
	return rows
