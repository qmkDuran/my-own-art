class_name MothSwarm
extends Skill
## Ember moths from the lantern: they flutter toward the cursor, then each finds an enemy. Tree: more moths,
## speed, Light on hit, cinder bursts, Linger, Guardians (shot-catching orbit), Matriarch (every 4th cast).

const SPREAD: float = 0.5
const GUARD_COUNT: int = 2
const GUARD_TIME: float = 6.0
const MATRIARCH_EVERY: int = 4
const GREAT_MULT: float = 3.0
const MOTH_HEART_MULT: int = 2
const MOTH_HEART_MORE: float = 0.6
const SILK_CHANCE: float = 0.15
const SILK_STUN: float = 0.5

var _casts: int = 0


func count() -> int:
	var n: int = int(data["count"]) + int(val("count")) + int(p.stats.v("moth_count"))
	return n * MOTH_HEART_MULT if p.stats.has_special("moth_heart") else n


## Brood of Embers: one moth rises from a body and seeks.
func loose_from(at: Vector2) -> void:
	var m: Moth = _release(Vector2.UP, false)
	m.position = at


func speed() -> float:
	return float(data["speed"]) * (1.0 + val("speed_pct") / 100.0)


func seek_range() -> float:
	return float(data["seek_range"])


func use(target: Vector2) -> void:
	_casts += 1
	var dir: Vector2 = (target - p.global_position).normalized()
	var n: int = count()
	for k: int in n:
		_release(dir.rotated((k - (n - 1) * 0.5) * SPREAD / maxf(1.0, n * 0.5)), false)
	if rank("matriarch") > 0 and _casts % MATRIARCH_EVERY == 0:
		_release(dir, true)
	if rank("guardians") > 0 and p.get_tree().get_nodes_in_group("moth_guards").is_empty():
		for k: int in GUARD_COUNT:
			var g: Moth = _release(dir, false)
			g.guardian = true
			g.life = GUARD_TIME
			g.orbit_phase = PI * k
	Audio.sfx("moths", -6.0, randf_range(0.95, 1.08))


func _release(dir: Vector2, great: bool) -> Moth:
	var m := Moth.new()
	m.skill = self
	m.great = great
	m.position = p.lantern_pos()
	m.velocity = dir * speed() * randf_range(0.8, 1.1)
	m.life = float(data["lifetime"])
	m.lives = 2 if rank("linger") > 0 else 1
	m.orbit_phase = randf() * TAU
	fx().add_child(m)
	return m


func moth_hit(e: Enemy, at: Vector2, great: bool) -> void:
	var more: float = (1.0 + val("damage_pct") / 100.0) * (GREAT_MULT if great else 1.0) * (MOTH_HEART_MORE if p.stats.has_special("moth_heart") else 1.0)
	var stun: float = SILK_STUN if p.stats.has_special("matron_silk") and randf() < SILK_CHANCE else 0.0
	Combat.hit_enemy(e, roll(), opts({"dir": e.global_position - at, "more": more, "knockback": 8.0, "stun": stun}))
	Fx.halo(fx(), at, 18.0, Pal.c("flame", 0.8), 0.2)
	p.light.add(val("light_per_hit") + (0.5 if p.stats.has_special("moth_light") else 0.0))
	if rank("fire_moths") > 0:
		Fx.burst(fx(), at, 10, Vector2(40, 110), 0.3, [Pal.c("sun"), Pal.c("flame"), Pal.c("ember", 0.0)])
		for o: Enemy in enemies_in_arc(at, Vector2.RIGHT, Moth.BURST_RADIUS, 360.0):
			if o != e:
				Combat.hit_enemy(o, roll(val("burst_pct")), opts({"dir": o.global_position - at}))


func info() -> Array:
	var r: Vector2 = shown_range()
	var rows: Array = [["%d moths, %d-%d each" % [count(), r.x, r.y], UiDraw.TEXT],
		["Seek range %d px, live %.1f s" % [roundi(seek_range()), float(data["lifetime"])], UiDraw.TEXT]]
	if rank("matriarch") > 0:
		rows.append(["Every %dth cast: a great moth (x%d, pierces)" % [MATRIARCH_EVERY, roundi(GREAT_MULT)], UiDraw.UP])
	return rows
