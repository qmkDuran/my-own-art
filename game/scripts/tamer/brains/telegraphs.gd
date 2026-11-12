class_name Telegraphs
extends RefCounted
## The warning every wind-up shows on the ground (yours and the opponent's: the same information for both sides):
## a cone for a close strike, a circle around it for a burst at itself, a circle where it aims otherwise, a line for
## a shot. Red for the opponent, gold for yours.

const WARN := Color(0.91, 0.31, 0.35, 0.9)
const OWN := Color(1.0, 0.84, 0.48, 0.55)
const SHOT_WIDTH: float = 22.0


static func show_for(c: Creature, m: Dictionary, aim: Vector2, time: float) -> void:
	var reach: float = c.hit_radius() * 1.5
	var fx: Node2D = TamerGame.current.fx_layer
	var t: Telegraph
	match String(m["kind"]):
		"strike":
			t = Telegraph.cone(fx, c.global_position, aim - c.global_position, float(m["range"]) + c.extra_reach() + reach, float(m.get("arc", 100.0)), time)
		"burst":
			var at: Vector2 = c.global_position if String(m.get("at", "aim")) == "self" else MoveKind.clamp_aim(c, m, aim)
			t = Telegraph.circle(fx, at, float(m["radius"]), time)
		"bolt":
			t = Telegraph.circle(fx, c.global_position, SHOT_WIDTH, time)
			t.lane = (aim - c.global_position).normalized() * float(m["range"])
		_:
			t = Telegraph.circle(fx, MoveKind.clamp_aim(c, m, aim), float(m.get("radius", reach * 2.0)), time)
	t.col = WARN if c.side != Combatant.SIDE_TEAM else OWN
