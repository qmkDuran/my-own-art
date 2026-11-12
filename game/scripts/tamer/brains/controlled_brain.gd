class_name ControlledBrain
extends CreatureBrain
## Your creature in battle, under your control: it goes where you left-click (hold to keep going), fights what you
## right-click (or swings its basic attack toward the cursor), and uses its moves at the cursor (TamerInput).

var goal: Vector2 = Vector2.INF
var target: Combatant


func think(delta: float) -> Vector2:
	var speed: float = c.rec.speed() * float(TamerData.rule("control.speed_mult"))
	if goal != Vector2.INF:
		var dir: Vector2 = c.steer_to(goal, delta)
		if dir == Vector2.ZERO:
			goal = Vector2.INF
		return dir * speed
	if target != null and is_instance_valid(target) and target.alive() and not (target is Creature and (target as Creature).dazed):
		return fight(target, delta, float(TamerData.rule("partner.basic_range_slack")), speed)
	return Vector2.ZERO
