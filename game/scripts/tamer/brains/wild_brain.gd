class_name WildBrain
extends CreatureBrain
## A wild creature (or a rival trainer's): it wanders near home until your creature comes close or it is hit, then
## fights your creature (never the trainer) the way its species does (FightStyle): every attack has a tell (a
## wind-up with a red warning) and an opening after it. Outside a battle it joins in; during one it ignores you unless
## it is in the fight (BattleMode). It walks home if pulled too far. Dazed, it only wobbles about.

const DAZED_SPEED: float = 0.25
const WANDER_SPEED: float = 0.35
const HOME_SPEED: float = 0.8
const DEFAULT_TELL: float = 0.45

var home: Vector2
var awake: bool = false
var pack: int = -1
var _target: Combatant
var _t: float = 0.0
var _wander_to: Vector2 = Vector2.INF
var _going_home: bool = false
var _windup: float = 0.0                ## > 0: winding up `_pending` toward `_aim` (a telegraph shows where)
var _pending: String = ""
var _aim: Vector2
var _opening: float = 0.0               ## after an attack it stands still this long: the moment to punish it
var _next_opening: float = 0.0
var style: FightStyle


func winding_at(c: Creature) -> bool:
	return _windup > 0.0 and _target == c


func windup_left() -> float:
	return _windup


func cancel_windup() -> void:
	_windup = 0.0


func after_team() -> bool:
	return awake and _target != null and not _going_home


func wake(by: Combatant = null) -> void:
	if not awake and not _going_home and TamerGame.current.battle.may_join(c):
		awake = true
		if by != null:
			_target = by
		TamerGame.current.battle.engage(c)                # it noticed your team: a battle starts
		for n: Node in c.get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
			var o := n as Creature
			if o != c and o.brain is WildBrain and (o.brain as WildBrain).pack == pack and pack >= 0:
				(o.brain as WildBrain).wake(by)


func think(delta: float) -> Vector2:
	var W: Dictionary = TamerData.rule("wild")
	if c.dazed:
		_windup = 0.0
		return _wander(delta, DAZED_SPEED)
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			c.cast(_pending, _aim)
			_opening = _next_opening
		return Vector2.ZERO
	if _opening > 0.0:
		_opening -= delta
		return Vector2.ZERO
	if _going_home:
		return _home(delta, W)
	_t -= delta
	if _t <= 0.0:
		_t = float(W["think"])
		_retarget(W)
	if not awake or _target == null or not is_instance_valid(_target) or not _target.alive():
		if _target == null:
			awake = false                                   # nothing of yours out: it calms down
		return _wander(delta, WANDER_SPEED)
	if c.global_position.distance_to(home) > float(W["chase_leash"]):
		_going_home = true
		return Vector2.ZERO
	if style == null:
		style = FightStyle.new(self)
	return style.think(_target, delta)


func _retarget(W: Dictionary) -> void:
	var partner: Creature = TamerGame.current.partner()
	var has: bool = partner != null and is_instance_valid(partner) and partner.alive()
	if not awake:
		var tr: Trainer = TamerGame.current.trainer
		var near: bool = tr.global_position.distance_to(c.global_position) < float(W["wake_range"]) or \
			(has and partner.global_position.distance_to(c.global_position) < float(W["wake_range"]))
		if near and has:
			wake(partner)
		return
	_target = partner if has else null                     # only ever your creature: the trainer is never a target


## Every wild attack is telegraphed: it stops, a warning shows where it will land, then it strikes there. Step out
## (or roll) and it misses.
func attack(id: String, target: Combatant) -> void:
	attack_with({"move": id, "windup": DEFAULT_TELL, "opening": DEFAULT_TELL}, target)


## An attack from the species' list: its own tell (wind-up) and opening.
func attack_with(a: Dictionary, target: Combatant) -> void:
	var id: String = String(a["move"])
	if _windup > 0.0 or not c.move_ready(id):
		return
	var m: Dictionary = TamerData.move(id)
	_pending = id
	_target = target
	_aim = target.global_position
	_windup = float(a["windup"])
	_next_opening = float(a.get("opening", 0.0))
	var fx: Node2D = TamerGame.current.fx_layer
	var t: Telegraph
	if m["kind"] == "strike":
		t = Telegraph.cone(fx, c.global_position, _aim - c.global_position, float(m["range"]) + target.hit_radius(), float(m.get("arc", 100.0)), _windup)
	elif m["kind"] == "burst" and String(m.get("at", "aim")) == "self":
		t = Telegraph.circle(fx, c.global_position, float(m["radius"]), _windup)
	else:
		t = Telegraph.circle(fx, MoveKind.clamp_aim(c, m, _aim), float(m.get("radius", target.hit_radius() * 2.0)), _windup)
	t.col = Color(Pal.c("rose"), 0.9)
	c.view.windup(_windup)


func _wander(delta: float, speed: float) -> Vector2:
	if _wander_to == Vector2.INF or c.global_position.distance_to(_wander_to) < Combatant.ARRIVE * 2.0:
		var W: float = float(TamerData.rule("wild.wander"))
		_wander_to = TamerGame.current.layout.free_spot_near(home + Vector2(randf_range(-W, W), randf_range(-W, W)), c.hit_radius())
	return c.steer_to(_wander_to, delta) * c.rec.speed() * speed


func _home(delta: float, W: Dictionary) -> Vector2:
	c.rec.life = minf(c.rec.max_life(), c.rec.life + float(W["regen"]) * c.rec.max_life() / 100.0 * delta * 10.0)
	if c.global_position.distance_to(home) < Combatant.ARRIVE * 4.0:
		_going_home = false
		awake = false
		_target = null
		return Vector2.ZERO
	return c.steer_to(home, delta) * c.rec.speed() * HOME_SPEED
