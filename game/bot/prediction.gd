class_name Prediction
## Where the player will be, worked out only from what the bot observed: a lead point for a slow glob (the target's
## observed velocity), where a player who slipped out of sight has probably got to, and which hiding spots lie along
## the way they were heading.


## The point to aim at so a glob of `speed` meets a target moving at `velocity` (no lead past max_time).
const NO_SPEED_DIFFERENCE: float = 0.0001


static func lead_point(from: Vector3, target: Vector3, velocity: Vector3, speed: float) -> Vector3:
	var offset: Vector3 = target - from
	var a: float = velocity.length_squared() - speed * speed
	var half_b: float = offset.dot(velocity)
	var c: float = offset.length_squared()
	var time: float = c / (speed * speed) if absf(a) < NO_SPEED_DIFFERENCE else _intercept_time(a, half_b, c)
	return target + velocity * clampf(time, 0.0, Tuning.ai_f("prediction", "max_lead_time"))


## Last known position pushed along the observed heading for the time it has been out of sight (capped).
static func predicted_position(last_known: Vector3, velocity: Vector3, unseen_for: float) -> Vector3:
	return last_known + velocity * minf(unseen_for, Tuning.ai_f("prediction", "flee_lookahead"))


## Hiding spots ahead along `heading` from `from`, best guess first (well aligned and near).
static func hideouts_ahead(spots: Array[HidingSpot], from: Vector3, heading: Vector3) -> Array[HidingSpot]:
	var cone: float = deg_to_rad(Tuning.ai_f("prediction", "concealment_cone_deg"))
	var reach: float = Tuning.ai_f("prediction", "concealment_reach")
	var ahead: Array[HidingSpot] = []
	for spot: HidingSpot in spots:
		var offset: Vector3 = spot.global_position - from
		offset.y = 0.0
		if offset.length() <= reach and (heading == Vector3.ZERO or heading.angle_to(offset) <= cone):
			ahead.append(spot)
	ahead.sort_custom(func(x: HidingSpot, y: HidingSpot) -> bool:
		return x.global_position.distance_to(from) < y.global_position.distance_to(from))
	return ahead


## The earliest positive root of a*t^2 + 2*half_b*t + c = 0 (0 when the glob can never catch up).
static func _intercept_time(a: float, half_b: float, c: float) -> float:
	var discriminant: float = half_b * half_b - a * c
	if discriminant < 0.0:
		return 0.0
	var root: float = sqrt(discriminant)
	var first: float = (-half_b - root) / a
	var second: float = (-half_b + root) / a
	if first > 0.0 and (second <= 0.0 or first < second):
		return first
	return maxf(second, 0.0)
