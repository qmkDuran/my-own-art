class_name Wickbolt
extends Skill
## The basic attack: he points the staff and the lantern spits a bolt of light at the cursor. Quick enough to cast
## without pause; every third bolt burns brighter. Tree: cast speed, range, ignite, Light on hit, pierce, a fork
## on impact, a burst on every third bolt (Third Light), a trail of embers, and a bonus against the Shrouded.

const THIRD_RESET: float = 1.2         ## a pause this long and the count of three starts again
const BURST_RADIUS: float = 56.0
const FORK_ANGLE: float = 0.6
const FORK_SPEED: float = 0.8
const FORK_AHEAD: float = 24.0
const TRAIL_PIECES: int = 3
const TRAIL_RADIUS: float = 16.0
const TRAIL_TIME: float = 2.0
const AIM_HEIGHT: float = 14.0         ## bolts fly at a body's middle, not its feet
const DROP_TIME: float = 0.1
const BOLT_SCALE: float = 3.0
const TEX: String = "res://art/fx/bolt.png"

var _count: int = 0
var _last: float = -10.0


func cast_time() -> float:
	return float(data["time"]) / (speed_mult() * (1.0 + val("speed_pct") / 100.0))


func reach() -> float:
	return float(data["range"]) * (1.0 + val("range_pct") / 100.0)


func speed() -> float:
	return float(data["speed"]) * (1.0 + val("range_pct") / 100.0)


## The cast-forward alternates sides so a stream of bolts does not look mechanical.
func pose() -> String:
	return "bolt%d" % (_count % 2 + 1)


func use(target: Vector2) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last > THIRD_RESET:
		_count = 0
	_last = now
	_count += 1
	var third: bool = _count % 3 == 0
	var from: Vector2 = Vector2(p.lantern_pos().x, p.global_position.y - AIM_HEIGHT)   # its track at body height
	var dir: Vector2 = (target - Vector2(0, AIM_HEIGHT) - from).normalized()
	if dir == Vector2.ZERO:
		dir = p.aim
	Fx.flash(fx(), p.lantern_pos(), 50.0 if third else 34.0, Pal.c("gold"), 1.3, 0.12)    # the staff flares at release
	Fx.halo(fx(), p.lantern_pos(), 22.0 if third else 14.0, Pal.c("sun", 0.9), 0.12)
	Audio.sfx("bolt", -8.0 if third else -11.0, randf_range(0.95, 1.1) * (0.85 if third else 1.0))
	var pr: Projectile = _bolt(from, dir, float(data["third_mult"]) if third else 1.0, third, true)
	_drop_from_lantern(pr, p.lantern_pos().y - from.y)
	if rank("ember_trail") > 0:
		_trail(dir)


func _bolt(from: Vector2, dir: Vector2, mult: float, third: bool, can_fork: bool) -> Projectile:
	var left: Array[int] = [1 + int(val("pierce"))]
	var shot: Array[Projectile] = []                     # the lambda captures this list, then the shot goes in it
	var pr: Projectile = Projectile.spawn(fx(), from, dir * speed() * (1.0 if can_fork else FORK_SPEED), PropSprite.tex(TEX),
		Pal.c("gold"), false, func(e: Node2D) -> void:
			_land(e as Enemy, dir, mult, third, can_fork)
			left[0] -= 1
			if left[0] <= 0 and not shot.is_empty() and is_instance_valid(shot[0]):
				shot[0].life = 0.0)
	shot.append(pr)
	pr.pierce = true
	pr.life = reach() / speed()
	pr.scale = Vector2.ONE * (BOLT_SCALE * (1.3 if third else 1.0))
	return pr


## The bolt leaves the lantern itself: its picture starts at the lantern and settles onto its track at body height.
func _drop_from_lantern(pr: Projectile, lift: float) -> void:
	for c: Node in pr.get_children():
		var n := c as Node2D
		if n is Line2D:                                          # the streak lives in world space
			continue
		n.position = Vector2(0, lift).rotated(-pr.rotation)          # "up" on screen, in the shot's turned frame
		pr.create_tween().tween_property(n, "position", Vector2.ZERO, DROP_TIME)


func _land(e: Enemy, dir: Vector2, mult: float, third: bool, can_fork: bool) -> void:
	var at: Vector2 = e.global_position + Vector2(0, -AIM_HEIGHT)
	_hit(e, dir, mult * (1.0 if can_fork else val("fork_pct") / 100.0), third)
	if third and rank("third_light") > 0:
		burst_at(at, val("burst_pct"), e)
	if can_fork and rank("fork") > 0:
		for side: float in [-1.0, 1.0]:
			var d: Vector2 = dir.rotated(side * FORK_ANGLE)
			_bolt(at + d * FORK_AHEAD, d, 1.0, false, false)


func _hit(e: Enemy, dir: Vector2, mult: float, heavy: bool) -> void:
	if not is_instance_valid(e) or e.dead:
		return
	var burn: float = val("burn_chance")
	if p.stats.has_special("long_night") and e.shrouded:
		burn = 100.0
	Combat.hit_enemy(e, roll(float(data["damage_pct"])), opts({"dir": dir, "more": mult, "heavy": heavy,
		"vs_shrouded_pct": val("vs_shrouded_pct"), "burn_chance": burn, "knockback": 22.0 if heavy else 10.0}))
	p.light.add(val("light_per_hit"))


## Third Light (and Tether's Flare Up): a burst of the bolt's light around a point for `pct`% damage, sparing `spare`.
func burst_at(at: Vector2, pct: float, spare: Enemy = null) -> void:
	Fx.halo(fx(), at, BURST_RADIUS, Pal.c("gold", 0.8), 0.25)
	for e: Enemy in enemies_in_arc(at, Vector2.RIGHT, BURST_RADIUS, 360.0):
		if e != spare:
			_hit(e, (e.global_position - at).normalized(), pct / 100.0, true)


func _trail(dir: Vector2) -> void:
	var b: Vector2 = base_range(val("trail_pct"))
	for k: int in TRAIL_PIECES:
		BurningGround.spawn(fx(), p.global_position + dir * reach() * (k + 1) / (TRAIL_PIECES + 1), TRAIL_RADIUS, TRAIL_TIME,
			(b.x + b.y) * 0.5, self)


func info() -> Array:
	var r: Vector2 = shown_range(float(data["damage_pct"]))
	var rows: Array = [["Damage: %d-%d sunfire (every third bolt x%.1f)" % [r.x, r.y, float(data["third_mult"])], UiDraw.TEXT],
		["Range: %d px" % roundi(reach()), UiDraw.TEXT], ["Cast time: %.2f s" % cast_time(), UiDraw.TEXT]]
	if rank("piercing") > 0:
		rows.append(["Pierces %d enem%s" % [int(val("pierce")), "y" if int(val("pierce")) == 1 else "ies"], UiDraw.UP])
	if rank("third_light") > 0:
		var w: Vector2 = shown_range(float(data["damage_pct"]) * val("burst_pct") / 100.0)
		rows.append(["Third Light: %d-%d around the third bolt" % [w.x, w.y], UiDraw.UP])
	return rows
