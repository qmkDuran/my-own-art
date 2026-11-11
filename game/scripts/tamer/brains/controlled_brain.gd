class_name ControlledBrain
extends CreatureBrain
## The creature you steer while holding the control key: it goes where you click or where the arrow keys point,
## a little quicker than usual, and fights what you click. Its moves still go to the cursor.

var goal: Vector2 = Vector2.INF
var target: Combatant


func think(delta: float) -> Vector2:
	var speed: float = c.rec.speed() * float(TamerData.rule("control.speed_mult"))
	var keys: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if keys.length() > 0.1:
		goal = Vector2.INF
		target = null
		return keys.normalized() * speed
	if target != null and is_instance_valid(target) and target.alive():
		return fight(target, delta, float(TamerData.rule("partner.basic_range_slack")), speed)
	if goal == Vector2.INF:
		return Vector2.ZERO
	var dir: Vector2 = c.steer_to(goal, delta)
	if dir == Vector2.ZERO:
		goal = Vector2.INF
	return dir * speed
