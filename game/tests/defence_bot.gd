class_name DefenceBot
extends Node
## Plays a defence night for the balance and stability tests: kites away from the creatures (with a pull back
## towards the middle of town so it doesn't pin itself on a wall), dodges when one gets close, walks over to
## relight snuffed lamps when it is safe, and picks level-up offers by a strategy.

const LOOK_RADIUS: float = 9.0
const DANGER: float = 1.6
const HOME_PULL: float = 0.04
const LAMP_SAFE: float = 5.0
const LAMP_PULL: float = 0.6
const HOME: Vector3 = Vector3(0, 0, 4)

var strategy: String = "random"
var picks: Array[String] = []
var _m: Main


func setup(main: Main, pick_strategy: String) -> void:
	name = "DefenceBot"
	_m = main
	strategy = pick_strategy
	_m.controller.enabled = false
	if _m.night.level_up_ready.is_connected(_m.level_panel.show_offers):
		_m.night.level_up_ready.disconnect(_m.level_panel.show_offers)
	if not _m.night.level_up_ready.is_connected(_choose):
		_m.night.level_up_ready.connect(_choose)


func _physics_process(_delta: float) -> void:
	if _m.night.state != NightRun.State.RUNNING:
		_m.player.wish = Vector3.ZERO
		return
	var me: Vector3 = _m.player.global_position
	var push := Vector3.ZERO
	var closest: float = INF
	for creature: Creature in _m.night.horde.within(me, LOOK_RADIUS):
		var away := Vector3(me.x - creature.global_position.x, 0.0, me.z - creature.global_position.z)
		closest = minf(closest, away.length())
		push += away.normalized() / maxf(away.length_squared(), 1.0)
	push += Vector3(HOME.x - me.x, 0.0, HOME.z - me.z) * HOME_PULL
	if closest > LAMP_SAFE:
		push += _lamp_pull(me)
	_m.player.wish = push.normalized()
	_m.player.running = true
	if closest < DANGER:
		_m.player.dash()


func _lamp_pull(me: Vector3) -> Vector3:
	for lamp: LampLight in _m.night.lamps.lamps:
		if not lamp.lit:
			return (lamp.global_position - me).normalized() * LAMP_PULL
	return Vector3.ZERO


func _choose(offers: Array[Dictionary]) -> void:
	var best: Dictionary = offers[0]
	for offer: Dictionary in offers:
		if _score(offer) > _score(best):
			best = offer
	picks.append(best["id"])
	_m.night.choose.call_deferred(best)


func _score(offer: Dictionary) -> float:
	if offer["kind"] == "combo":
		return INF
	match strategy:
		"attacks_first":
			return 2.0 if offer["kind"] == "attacks" else 1.0
		"passives_first":
			return 2.0 if offer["kind"] == "passives" else 1.0
		"random":
			return randf()
	return 2.0 if offer["id"] == strategy else randf()
