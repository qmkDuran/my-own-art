class_name WildBrain
extends CreatureBrain
## A wild creature: it wanders near home until something of yours comes close or hits it, then fights (its partner-
## like basic attack, sometimes one of its moves), going for your creature unless you are much closer or alone. It
## gives up and walks home if pulled too far. Dazed (weak enough to befriend), it only wobbles about.

const DAZED_SPEED: float = 0.25
const WANDER_SPEED: float = 0.35
const HOME_SPEED: float = 0.8

var home: Vector2
var awake: bool = false
var pack: int = -1
var _target: Combatant
var _t: float = 0.0
var _wander_to: Vector2 = Vector2.INF
var _going_home: bool = false


func after_team() -> bool:
	return awake and _target != null and not _going_home


func wake(by: Combatant = null) -> void:
	if not awake and not _going_home:
		awake = true
		if by != null:
			_target = by
		for n: Node in c.get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
			var o := n as Creature
			if o != c and o.brain is WildBrain and (o.brain as WildBrain).pack == pack and pack >= 0:
				(o.brain as WildBrain).wake(by)


func think(delta: float) -> Vector2:
	var W: Dictionary = TamerData.rule("wild")
	if c.dazed:
		return _wander(delta, DAZED_SPEED)
	if _going_home:
		return _home(delta, W)
	_t -= delta
	if _t <= 0.0:
		_t = float(W["think"])
		_retarget(W)
	if not awake or _target == null or not is_instance_valid(_target) or not _target.alive():
		return _wander(delta, WANDER_SPEED)
	if c.global_position.distance_to(home) > float(W["chase_leash"]):
		_going_home = true
		return Vector2.ZERO
	if randf() < float(W["move_chance"]) * delta:
		_try_move()
	return fight(_target, delta, float(W["basic_range_slack"]), c.rec.speed())


func _retarget(W: Dictionary) -> void:
	var partner: Creature = TamerGame.current.partner()
	var tr: Trainer = TamerGame.current.trainer
	if not awake:
		for f: Combatant in c.foes():
			if f.global_position.distance_to(c.global_position) < float(W["wake_range"]):
				wake(f)
				return
		return
	var d_tr: float = tr.global_position.distance_to(c.global_position)
	if partner == null or not partner.alive():
		_target = tr if tr.alive() else null
	elif d_tr < partner.global_position.distance_to(c.global_position) * float(W["trainer_aggro"]):
		_target = tr
	else:
		_target = partner


## One of its kit moves at the target, now and then (wild creatures use the same moves as yours).
func _try_move() -> void:
	var kit: Array = c.rec.moves()
	var id: String = String(kit[randi() % kit.size()])
	var m: Dictionary = TamerData.move(id)
	if m["kind"] == "guard" or c.global_position.distance_to(_target.global_position) > float(m.get("range", 120.0)) + 40.0:
		return
	c.cast(id, _target.global_position)


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
