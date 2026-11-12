class_name FightStyle
extends RefCounted
## How a species fights (species.json "ai"), used by FoeBrain for arena opponents.
## flanker (maned wolf): circles to your side, dashes in, then runs off and comes again. brawler (Tasmanian devil):
## walks straight at you and commits to heavy lunges with long tells and long openings after. skirmisher (aye-aye):
## keeps its distance, pulses when you get close, and backs further off when hurt. Each attack has a tell (wind-up)
## and an opening after it (it stands still: punish it).

const FLANK_TIME: float = 1.6
const STRAFE: float = 0.6
const BACK_OFF: float = 0.7

var b: FoeBrain
var ai: Dictionary
var _phase: String = "approach"
var _phase_t: float = 0.0
var _side: float = 1.0


func _init(brain: FoeBrain) -> void:
	b = brain
	ai = brain.c.rec.data().get("ai", {"style": "brawler", "attacks": []})
	_side = 1.0 if randf() < 0.5 else -1.0


## It lost sight of you (grass, fog, camouflage): it drifts toward where you were.
func search(target: Creature, delta: float) -> Vector2:
	return b.c.steer_to(target.global_position + Vector2(_side * 60.0, 0), delta) * b.c.speed() * STRAFE


func think(target: Creature, delta: float) -> Vector2:
	_phase_t -= delta
	match String(ai["style"]):
		"flanker":
			return _flanker(target, delta)
		"skirmisher":
			return _skirmisher(target, delta)
	return _brawler(target, delta)


## The first of its attacks that is ready and whose reach fits the distance (nearest-first in data order).
func pick(d: float) -> Dictionary:
	for a: Dictionary in ai["attacks"]:
		if d <= float(a["reach"]) and d >= float(a.get("min", 0.0)) and b.c.move_ready(String(a["move"])):
			return a
	return {}


## Its best attack for the distance, or its basic (the same right-click combo as yours) when it is close.
func _try(target: Creature) -> bool:
	var d: float = b.c.global_position.distance_to(target.global_position) - b.c.extra_reach() - target.extra_reach()
	var a: Dictionary = pick(d)
	if a.is_empty() and d <= b.basic_reach(1.0) - b.c.extra_reach() + target.hit_radius():
		a = {"move": b.basic_id(), "opening": 0.0}
	return not a.is_empty() and b.attack_with(a, target)


func _brawler(target: Creature, delta: float) -> Vector2:
	if _try(target):
		return Vector2.ZERO
	return b.c.steer_to(target.global_position, delta) * b.c.speed()


func _flanker(target: Creature, delta: float) -> Vector2:
	var me: Vector2 = b.c.global_position
	var to: Vector2 = target.global_position - me
	if _phase == "retreat":
		if _phase_t <= 0.0:
			_phase = "approach"
			_phase_t = FLANK_TIME
			_side = -_side
		return b.c.steer_to(target.global_position - to.normalized() * float(ai["retreat"]), delta) * b.c.speed()
	var flank: Vector2 = target.global_position + to.normalized().orthogonal() * float(ai["flank"]) * _side
	if (me.distance_to(flank) < 30.0 or _phase_t <= 0.0) and _try(target):
		_phase = "retreat"
		_phase_t = float(ai["retreat_time"])
		return Vector2.ZERO
	return b.c.steer_to(flank, delta) * b.c.speed()


func _skirmisher(target: Creature, delta: float) -> Vector2:
	var me: Vector2 = b.c.global_position
	var d: float = me.distance_to(target.global_position)
	var keep: float = float(ai["flee_keep"]) if b.c.rec.life_frac() < float(ai["flee_below"]) else float(ai["keep"])
	if _try(target):
		return Vector2.ZERO
	var away: Vector2 = (me - target.global_position).normalized()
	if d < keep * 0.8:                                     # backs off slower than it chases: it can be caught
		return b.c.steer_to(me + away * 80.0 + away.orthogonal() * 40.0 * _side, delta) * b.c.speed() * BACK_OFF
	if d > keep * 1.3:
		return b.c.steer_to(target.global_position, delta) * b.c.speed()
	return b.c.steer_to(me + away.orthogonal() * 60.0 * _side, delta) * b.c.speed() * STRAFE
