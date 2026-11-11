class_name Tether
extends Skill
## A tether of light shoots from the lantern: the first enemy it catches (two with Double Tether) is yanked to your
## feet and stunned. Drag the Light feeds the lantern; Flare Up bursts light around the catch.

const LINE_W: float = 16.0
const PULL: float = 420.0
const FLARE_UP_PCT: float = 70.0


func reach() -> float:
	return float(data["range"]) * (1.0 + val("range_pct") / 100.0)


func use(target: Vector2) -> void:
	var dir: Vector2 = (target - p.global_position).normalized()
	Audio.sfx("bolt", -6.0, 0.7)
	var caught: Array[Enemy] = _in_line(dir).slice(0, 2 if rank("double_tether") > 0 else 1)
	var end: Vector2 = caught[0].global_position + Vector2(0, -14) if not caught.is_empty() else p.global_position + dir * reach()
	TetherFx.cast(fx(), p, end)
	for e: Enemy in caught:
		Combat.hit_enemy(e, roll(), opts({"dir": -dir, "more": 1.0 + val("damage_pct") / 100.0,
			"stun": float(data["stun"]), "knockback": 0.0, "heavy": true}))
		if is_instance_valid(e) and not e.dead and e.rank != "boss":
			e.pull_toward(p.global_position, PULL)
		p.light.add(val("light"))
		if rank("snap") > 0 and is_instance_valid(e):
			(p.skills.skill("wickbolt") as Wickbolt).burst_at(e.global_position + Vector2(0, -14), FLARE_UP_PCT)


func _in_line(dir: Vector2) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for n: Node in p.get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		var d: Vector2 = e.global_position - p.global_position
		var along: float = d.dot(dir)
		if along > 0.0 and along < reach() and absf(d.cross(dir)) < LINE_W + e.radius:
			out.append(e)
	out.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.global_position.distance_to(p.global_position) < b.global_position.distance_to(p.global_position))
	return out


func info() -> Array:
	var r: Vector2 = shown_range()
	return [["Reach %d px, %d-%d, stuns %.1f s, yanks to you" % [roundi(reach()), r.x, r.y, float(data["stun"])], UiDraw.TEXT]]
