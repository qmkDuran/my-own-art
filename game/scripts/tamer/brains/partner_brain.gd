class_name PartnerBrain
extends CreatureBrain
## Your creature outside battle (the route, the Gate Hall): it walks at your side, a little behind and never in
## your way (you do not collide), hurries when it falls behind, and catches up at once if it gets lost.

const STOP_NEAR: float = 0.4
const FAST: float = 1.0


func think(delta: float) -> Vector2:
	var tr: Trainer = TamerGame.current.trainer
	var P: Dictionary = TamerData.rule("partner")
	if c.global_position.distance_to(tr.global_position) > float(P["teleport_after"]):
		c.global_position = TamerGame.current.layout.free_spot_near(tr.global_position + Vector2(-20, 10), c.hit_radius())
	var back: Vector2 = -tr.heading * float(P["follow"]) + tr.heading.orthogonal() * float(P["follow_side"])
	var spot: Vector2 = tr.global_position + back
	var d: float = c.global_position.distance_to(spot)
	if d < float(P["follow"]) * STOP_NEAR:
		return Vector2.ZERO
	var hurry: float = float(P["catch_up"]) if d > float(P["follow"]) * 2.0 else FAST
	return c.steer_to(spot, delta) * c.speed() * hurry * clampf(d / float(P["follow"]), 0.3, 1.0)
