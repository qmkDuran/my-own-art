class_name FightStyle
extends RefCounted
## How a species moves in a fight (species.json "ai.style", one of the four in styles.json), used by FoeBrain for any
## creature the AI plays. brawler: walks straight in. kiter: keeps its distance, backs off slower than it chases (it
## can be caught), further when hurt. tank: advances slowly, holds its ground, channels its status move when hurt.
## flanker: circles to your side, strikes, runs off and comes again. Attacks are its species' moves with their own
## wind-ups (the same as yours), and the pause it takes after each is its opening.

const FLANK_TIME: float = 1.6
const STRAFE: float = 0.6
const BACK_OFF: float = 0.7

var b: FoeBrain
var ai: Dictionary
var S: Dictionary                       ## its style's numbers
var _phase: String = "approach"
var _phase_t: float = 0.0
var _side: float = 1.0


func _init(brain: FoeBrain) -> void:
	b = brain
	ai = brain.c.rec.data()["ai"]
	S = TamerData.styles[String(ai["style"])]
	_side = 1.0 if randf() < 0.5 else -1.0


## It lost sight of you (grass, fog, smoke, camouflage): it drifts toward where you were.
func search(target: Creature, delta: float) -> Vector2:
	return b.c.steer_to(target.global_position + Vector2(_side * 60.0, 0), delta) * b.c.speed() * STRAFE


func think(target: Creature, delta: float) -> Vector2:
	_phase_t -= delta
	match String(ai["style"]):
		"flanker":
			return _flanker(target, delta)
		"kiter":
			return _kiter(target, delta)
		"tank":
			return _tank(target, delta)
	return _brawler(target, delta)


## The first of its attacks that is ready and whose reach fits the distance (nearest-first in data order).
func pick(d: float) -> Dictionary:
	for a: Dictionary in attacks():
		if d <= float(a["reach"]) and d >= float(a.get("min", 0.0)) and b.c.move_ready(String(a["move"])):
			return a
	return {}


## Its species' attacks, and an alpha's signature move on top.
func attacks() -> Array:
	var out: Array = ai["attacks"].duplicate()
	if b.c.rec.alpha:
		var extra: Dictionary = (b.c.rec.A()["attack"] as Dictionary).duplicate()
		extra["move"] = b.c.rec.signature_move()
		out.push_front(extra)
	return out


## Its best attack for the distance, or its basic (the same right-click combo as yours) when it is close.
func _try(target: Creature) -> bool:
	var d: float = b.c.global_position.distance_to(target.global_position) - b.c.extra_reach() - target.extra_reach()
	var deny: Dictionary = b.tactics.deny(target)
	var a: Dictionary = deny if not deny.is_empty() else pick(d)
	if a.is_empty() and d <= b.basic_reach(1.0) - b.c.extra_reach() + target.hit_radius():
		a = {"move": b.basic_id(), "opening": 0.0}
	return not a.is_empty() and b.attack_with(a, target)


func _brawler(target: Creature, delta: float) -> Vector2:
	if _try(target):
		return Vector2.ZERO
	return b.c.steer_to(target.global_position, delta) * b.c.speed()


func _tank(target: Creature, delta: float) -> Vector2:
	if b.c.rec.life_frac() < float(S["guard_below"]):
		for a: Dictionary in ai["attacks"]:
			if String(TamerData.move(String(a["move"]))["type"]) == "status" and b.attack_with(a, target):
				return Vector2.ZERO
	if _try(target):
		return Vector2.ZERO
	return b.c.steer_to(target.global_position, delta) * b.c.speed() * float(S["advance"])


func _flanker(target: Creature, delta: float) -> Vector2:
	var me: Vector2 = b.c.global_position
	var to: Vector2 = target.global_position - me
	if _phase == "retreat":
		if _phase_t <= 0.0:
			_phase = "approach"
			_phase_t = FLANK_TIME
			_side = -_side
		return b.c.steer_to(target.global_position - to.normalized() * float(S["retreat"]), delta) * b.c.speed()
	var flank: Vector2 = target.global_position + to.normalized().orthogonal() * float(S["flank"]) * _side
	if (me.distance_to(flank) < 30.0 or _phase_t <= 0.0) and _try(target):
		_phase = "retreat"
		_phase_t = float(S["retreat_time"])
		return Vector2.ZERO
	return b.c.steer_to(flank, delta) * b.c.speed()


func _kiter(target: Creature, delta: float) -> Vector2:
	var me: Vector2 = b.c.global_position
	var d: float = me.distance_to(target.global_position)
	var keep: float = float(S["flee_keep"]) if b.c.rec.life_frac() < float(S["flee_below"]) else float(S["keep"])
	if _try(target):
		return Vector2.ZERO
	var away: Vector2 = (me - target.global_position).normalized()
	if d < keep * 0.8:                                     # backs off slower than it chases: it can be caught
		return b.c.steer_to(me + away * 80.0 + away.orthogonal() * 40.0 * _side, delta) * b.c.speed() * BACK_OFF
	if d > keep * 1.3:
		return b.c.steer_to(target.global_position, delta) * b.c.speed()
	return b.c.steer_to(me + away.orthogonal() * 60.0 * _side, delta) * b.c.speed() * STRAFE
