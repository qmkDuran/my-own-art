class_name CreatureBrain
extends RefCounted
## What a creature wants to do each frame, as a velocity. On the route partners follow the trainer and wild ones
## roam by temperament; in an arena your creature goes where you point and the opponent fights (FoeBrain).

var c: Creature


func _init(creature: Creature) -> void:
	c = creature


func think(_delta: float) -> Vector2:
	return Vector2.ZERO


## Every frame, even while the creature can't move (channelling, committed, stunned).
func tick(_delta: float) -> void:
	pass


## Range of the creature's auto-attack (basic move), with some slack so it stands inside it.
func basic_reach(slack: float) -> float:
	return float(TamerData.move(String(c.rec.data()["basic"]))["range"]) * slack


func basic_id() -> String:
	return String(c.rec.data()["basic"])


## Walk into reach of `target` and use the basic move on it; returns the velocity.
func fight(target: Combatant, delta: float, slack: float, speed: float) -> Vector2:
	var reach: float = basic_reach(slack) + target.hit_radius()
	var d: float = c.global_position.distance_to(target.global_position)
	if d > reach:
		return c.steer_to(target.global_position, delta) * speed
	c.face(target.global_position)
	attack(basic_id(), target)
	return Vector2.ZERO


## Uses a move on the target; opponents telegraph first (FoeBrain).
func attack(id: String, target: Combatant) -> void:
	c.cast(id, target.global_position)
