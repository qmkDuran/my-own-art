class_name FoeTactics
extends RefCounted
## What makes an opponent smarter, by tier (tamer.json "ai_tiers"): it takes a moment to react, may dodge when you
## wind up a move, leads its shots, steps behind cover when hurt, takes the high ground, hides in tall grass, saves
## its gauge for a full bar or a staggered target, and sometimes channels its status move when you are far away.

const COVER_BELOW: float = 0.5
const RETHINK: float = 1.2
const FAR_FOR_STATUS: float = 160.0
const DODGE_SIDE: float = 90.0

var b: FoeBrain
var _react: float = 0.0
var _plan: Vector2 = Vector2.INF        ## a spot it is heading for (cover or grass)
var _plan_t: float = 0.0
var _seen_commit: bool = false


func _init(brain: FoeBrain) -> void:
	b = brain


func T() -> Dictionary:
	return b.tier


## A movement that overrides its style this frame, or Vector2.INF.
func think(target: Creature, delta: float) -> Vector2:
	_react -= delta
	_plan_t -= delta
	if _dodge_windup(target):
		return Vector2.ZERO
	if _react > 0.0:
		return Vector2.ZERO
	if _plan != Vector2.INF and _plan_t > 0.0:
		var dir: Vector2 = b.c.steer_to(_plan, delta)
		if dir != Vector2.ZERO:
			return dir * b.c.speed()
		_plan = Vector2.INF
	if _plan_t <= 0.0:
		_plan_t = RETHINK
		_plan = _choose_spot(target)
	return Vector2.INF


## When your creature starts winding up a move, it may hop aside (once per wind-up), after its reaction time.
func _dodge_windup(target: Creature) -> bool:
	var winding: bool = target.commit_t > 0.0
	if winding and not _seen_commit:
		_seen_commit = true
		_react = float(T()["react"])
		if randf() < float(T()["dodge"]):
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
			if b.c.gauge + 0.001 < cost:
				return false
			if bool(T()["save_gauge"]):
				return b.c.gauge >= float(TamerData.rule("combat.gauge.segments")) - 0.01 or target.stagger.is_staggered()
			return true
		"status":
			return target.global_position.distance_to(b.c.global_position) > FAR_FOR_STATUS and randf() < float(T()["status"])
	return true


## Where to aim a shot: at the target, or (better tiers) where it will be when the shot arrives.
func lead(target: Creature, m: Dictionary) -> Vector2:
	var speed: float = float(m["speed"]) * float(TamerData.rule("combat.bolt_speed_mult"))
	var travel: float = b.c.global_position.distance_to(target.global_position) / maxf(speed, 1.0)
	return target.global_position + target.velocity * travel * float(T()["lead"])
