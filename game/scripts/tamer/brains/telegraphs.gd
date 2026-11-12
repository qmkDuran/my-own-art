class_name Telegraphs
extends RefCounted
## The red warning an opponent's attack shows while it winds up: a cone for a close strike, a circle around it for a
## burst at itself, a circle where it aims otherwise, a line for a shot.

const WARN := Color(0.91, 0.31, 0.35, 0.9)
const SHOT_WIDTH: float = 22.0


static func show_for(c: Creature, m: Dictionary, aim: Vector2, target: Creature, time: float) -> void:
	var fx: Node2D = TamerGame.current.fx_layer
	var t: Telegraph
	match String(m["kind"]):
		"strike":
			t = Telegraph.cone(fx, c.global_position, aim - c.global_position, float(m["range"]) + target.hit_radius(), float(m.get("arc", 100.0)), time)
		"burst":
			var at: Vector2 = c.global_position if String(m.get("at", "aim")) == "self" else MoveKind.clamp_aim(c, m, aim)
			t = Telegraph.circle(fx, at, float(m["radius"]), time)
		"bolt":
			t = Telegraph.circle(fx, c.global_position, SHOT_WIDTH, time)
			t.lane = (aim - c.global_position).normalized() * float(m["range"])
		_:
			t = Telegraph.circle(fx, MoveKind.clamp_aim(c, m, aim), float(m.get("radius", target.hit_radius() * 2.0)), time)
	t.col = WARN
