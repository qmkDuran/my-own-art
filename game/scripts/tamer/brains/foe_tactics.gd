class_name FoeTactics
extends RefCounted
## What makes an opponent smarter, by tier (tamer.json "ai_tiers"; decisions only, never stats): it takes a moment
## to react, may dodge when you wind up a move, leads its shots, steps behind cover when hurt, takes the high ground,
## hides in tall grass, saves its gauge for a full bar or a staggered target, and sometimes channels its status move
## when you are far away. Hard also BAITS (steps into your range when you have gauge and stands there, then dodges
## the moment you commit), PUSHES (gets on the far side of you from a wall, rock, thorns or the ledge edge, so its
## knockback slams you into it) and DENIES your home terrain (burns or flattens it under you).

const COVER_BELOW: float = 0.5
const RETHINK: float = 1.2
const FAR_FOR_STATUS: float = 160.0
const DODGE_SIDE: float = 90.0
const BAIT_RANGE: float = 170.0         ## where it stands to bait: inside most of your moves' reach
const BAIT_TIME: float = 1.4
const PUSH_NEAR: float = 110.0          ## a hazard this close behind you is worth pushing you into
const PUSH_STAND: float = 60.0
const HAZARDS: Array[int] = [ArenaLayout.F.WALL, ArenaLayout.F.ROCK, ArenaLayout.F.TREE, ArenaLayout.F.THORNS, ArenaLayout.F.PIT]

var b: FoeBrain
var _plan: Vector2 = Vector2.INF        ## a spot it is heading for (cover or grass)
var _plan_t: float = 0.0
var _seen_commit: bool = false
var _baiting: float = 0.0              ## > 0: standing in your range on purpose, ready to dodge
var _deny_ready: bool = false
var baits_dodged: int = 0


func _init(brain: FoeBrain) -> void:
	b = brain


func T() -> Dictionary:
	return b.tier


## A movement that overrides its style this frame, or Vector2.INF.
func think(target: Creature, delta: float) -> Vector2:
	_plan_t -= delta
	_baiting -= delta
	if _dodge_windup(target):
		return Vector2.ZERO
	if _plan != Vector2.INF and _plan_t > 0.0:
		var dir: Vector2 = b.c.steer_to(_plan, delta)
		if dir != Vector2.ZERO:
			return dir * b.c.speed()
		_plan = Vector2.INF
	if _baiting > 0.0 and b.c.global_position.distance_to(target.global_position) < BAIT_RANGE * 1.2:
		b.c.face(target.global_position)
		return Vector2.ZERO
	if _plan_t <= 0.0:
		_plan_t = RETHINK
		_deny_ready = randf() < float(T()["deny"])
		_plan = _choose_spot(target)
	return Vector2.INF


## When your creature starts winding up a move, it may hop aside (once per wind-up), after its reaction time.
func _dodge_windup(target: Creature) -> bool:
	var winding: bool = target.commit_t > 0.0
	if winding and not _seen_commit:
		_seen_commit = true
		var baited: bool = _baiting > 0.0
		if baited:
			baits_dodged += 1
			_baiting = 0.0
		if baited or randf() < float(T()["dodge"]):
			var side: Vector2 = (b.c.global_position - target.global_position).normalized().orthogonal()
			b.c.get_tree().create_timer(float(T()["react"]), false).timeout.connect(func() -> void:
				if is_instance_valid(b.c) and b.c.alive():
					b.c.dodge(b.c.global_position + side * DODGE_SIDE * (1.0 if randf() < 0.5 else -1.0), TamerData.rule("control.dodge")))
			return true
	elif not winding:
		_seen_commit = false
	return false


## Hurt: a spot behind cover from you. Otherwise maybe a patch of tall grass to hide in.
func _choose_spot(target: Creature) -> Vector2:
	var a: Arena = TerrainRules.arena()
	if a == null:
		return Vector2.INF
	if b.c.rec.life_frac() < COVER_BELOW and randf() < float(T()["cover"]):
		return _behind_cover(a, target)
	if target.gauge_now() >= 1.0 and randf() < float(T()["bait"]):
		return bait(target)
	if randf() < float(T()["push"]):
		var push: Vector2 = _push_spot(a, target)
		if push != Vector2.INF:
			return push
	if b.c.global_position.distance_to(target.global_position) > FAR_FOR_STATUS and randf() < float(T()["high_ground"]):
		return _nearest(a, ArenaLayout.F.LEDGE)
	if randf() < float(T()["grass"]):
		return _nearest(a, ArenaLayout.F.GRASS)
	return Vector2.INF


func _behind_cover(a: Arena, target: Creature) -> Vector2:
	var best := Vector2.INF
	for y: int in a.layout.rows:
		for x: int in a.layout.cols:
			var c := Vector2i(x, y)
			if not ArenaLayout.SHOT_BLOCK.has(a.layout.f(c)) or a.layout.f(c) == ArenaLayout.F.WALL:
				continue
			var away: Vector2 = (a.layout.center_of(c) - target.global_position).normalized()
			var spot: Vector2 = a.layout.center_of(c) + away * a.layout.cell
			if a.layout.point_free(spot, b.c.hit_radius()) and (best == Vector2.INF or
					spot.distance_to(b.c.global_position) < best.distance_to(b.c.global_position)):
				best = spot
	return best


func _nearest(a: Arena, f: int) -> Vector2:
	var best := Vector2.INF
	for y: int in a.layout.rows:
		for x: int in a.layout.cols:
			var p: Vector2 = a.layout.center_of(Vector2i(x, y))
			if a.layout.f(Vector2i(x, y)) == f and (best == Vector2.INF or p.distance_to(b.c.global_position) < best.distance_to(b.c.global_position)):
				best = p
	return best


## May it use this move now? Specials need gauge (a careful one waits for a full bar or a staggered target);
## a status move only sometimes, and only with room to channel it.
func may_use(m: Dictionary, target: Creature) -> bool:
	match String(m["type"]):
		"special":
			var cost: float = float(m.get("cost", 0))
			if b.c.gauge_now() + 0.001 < cost:
				return false
			if bool(T()["save_gauge"]):
				return b.c.gauge_now() >= float(TamerData.rule("combat.gauge.segments")) - 0.01 or target.stagger.is_staggered()
			return true
		"status":
			return target.global_position.distance_to(b.c.global_position) > FAR_FOR_STATUS and randf() < float(T()["status"])
	return true


## Steps to just inside your reach and stands there, ready to dodge your move.
func bait(target: Creature) -> Vector2:
	_baiting = BAIT_TIME
	var from: Vector2 = (b.c.global_position - target.global_position).normalized()
	return target.global_position + from * BAIT_RANGE


## The spot on the far side of you from the nearest hazard behind you (its knockback will slam you into it).
func _push_spot(a: Arena, target: Creature) -> Vector2:
	var best := Vector2.INF
	var t: Vector2 = target.global_position
	var c0: Vector2i = a.layout.cell_of(t)
	var r: int = int(ceil(PUSH_NEAR / a.layout.cell))
	for y: int in range(c0.y - r, c0.y + r + 1):
		for x: int in range(c0.x - r, c0.x + r + 1):
			var p: Vector2 = a.layout.center_of(Vector2i(x, y))
			if HAZARDS.has(a.layout.f(Vector2i(x, y))) and p.distance_to(t) < PUSH_NEAR and (best == Vector2.INF or p.distance_to(t) < best.distance_to(t)):
				best = p
	if best == Vector2.INF:
		return best
	return a.layout.free_spot_near(t + (t - best).normalized() * PUSH_STAND, b.c.hit_radius())


## Your creature stands on its home terrain: an attack that burns or flattens it, if it has one ready ({} if not).
func deny(target: Creature) -> Dictionary:
	if not _deny_ready or TerrainRules.home(target).is_empty():
		return {}
	var d: float = b.c.global_position.distance_to(target.global_position)
	for a: Dictionary in b.style.attacks():
		var m: Dictionary = TamerData.move(String(a["move"]))
		if (bool(m.get("burns", false)) or bool(m.get("gale", false))) and d <= float(a["reach"]) and b.c.move_ready(String(a["move"])) and may_use(m, target):
			_deny_ready = false
			return a
	return {}


## Where to aim a shot: at the target, or (better tiers) where it will be when the shot arrives.
func lead(target: Creature, m: Dictionary) -> Vector2:
	var speed: float = float(m["speed"]) * float(TamerData.rule("combat.bolt_speed_mult"))
	var travel: float = b.c.global_position.distance_to(target.global_position) / maxf(speed, 1.0) + float(m.get("windup", 0.0))
	return target.global_position + target.velocity * travel * float(T()["lead"])
