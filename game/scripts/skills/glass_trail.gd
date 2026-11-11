class_name GlassTrail
extends RefCounted
## Glasswalker Treads (unique): Wickstep leaves glass behind that cuts enemies crossing it.

const PIECES: int = 4
const RADIUS: float = 18.0
const TIME: float = 2.5
const PCT: float = 40.0


static func lay(parent: Node, from: Vector2, dir: Vector2, p: Player) -> void:
	var dist: float = float(GameData.player["dash"]["distance"])
	var s: Skill = p.skills.skill("wickbolt")
	var b: Vector2 = s.base_range(PCT)
	for k: int in PIECES:
		BurningGround.spawn(parent, from + dir * dist * k / PIECES, RADIUS, TIME, (b.x + b.y) * 0.5, s)
