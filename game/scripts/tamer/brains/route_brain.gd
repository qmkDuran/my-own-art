class_name RouteBrain
extends CreatureBrain
## A wild creature on the route, by temperament (species "temperament"; tamer.json "temperament"). It never forces a
## fight: shy ones run from you, calm ones ignore you, territorial ones stop and warn (a "!" and a growl) when you
## come close and calm down when you back off, and the rare aggressive one (a red eye glint) chases you. Walking into
## it starts a battle (TamerGame.encounter).

const WANDER_SPEED: float = 0.35
const FLEE_SPEED: float = 1.0
const CHASE_SPEED: float = 0.9
const WARN_EVERY: float = 1.2

var home: Vector2
var temperament: String = "calm"
var _wander_to: Vector2 = Vector2.INF
var _warn_t: float = 0.0
var _calm_t: float = 0.0


func _init(creature: Creature, at: Vector2) -> void:
	super(creature)
	home = at
	temperament = String(creature.rec.data().get("temperament", "calm"))
	var R: Dictionary = TamerData.rule("temperament")
	if randf() < float(R["aggressive_chance"]):
		temperament = "aggressive"


func warning() -> bool:
	return _calm_t > 0.0


func chasing() -> bool:
	return temperament == "aggressive" and TamerGame.current.trainer.global_position.distance_to(c.global_position) < float(TamerData.rule("temperament.chase_range"))


func think(delta: float) -> Vector2:
	var R: Dictionary = TamerData.rule("temperament")
	var tr: Trainer = TamerGame.current.trainer
	var d: float = tr.global_position.distance_to(c.global_position)
	if d < float(TamerData.rule("battle.contact")) + c.hit_radius():
		TamerGame.current.encounter(c)
		return Vector2.ZERO
	match temperament:
		"shy":
			if d < float(R["flee_range"]):
				return c.steer_to(c.global_position + (c.global_position - tr.global_position).normalized() * 80.0, delta) * c.speed() * FLEE_SPEED
		"territorial":
			if _territory(d, delta, R):
				return Vector2.ZERO
		"aggressive":
			if d < float(R["chase_range"]):
				return c.steer_to(tr.global_position, delta) * c.speed() * CHASE_SPEED
	return _wander(delta)


## Too close: it stops, faces you and warns now and then; once you have backed off it calms after a while.
func _territory(d: float, delta: float, R: Dictionary) -> bool:
	_warn_t -= delta
	if d < float(R["warn"]):
		_calm_t = float(R["calm_after"])
		c.face(TamerGame.current.trainer.global_position)
		if _warn_t <= 0.0:
			_warn_t = WARN_EVERY
			TamerFx.word(c.global_position, "!", Pal.c("rose"), UiDraw.TITLE)
			Audio.sfx("hiss", -10.0, 0.9)
		return true
	_calm_t = maxf(0.0, _calm_t - delta)
	return _calm_t > 0.0


func _wander(delta: float) -> Vector2:
	if _wander_to == Vector2.INF or c.global_position.distance_to(_wander_to) < Combatant.ARRIVE * 2.0:
		var W: float = float(TamerData.rule("wild.wander"))
		_wander_to = TamerGame.current.layout.free_spot_near(home + Vector2(randf_range(-W, W), randf_range(-W, W)), c.hit_radius())
	return c.steer_to(_wander_to, delta) * c.speed() * WANDER_SPEED
