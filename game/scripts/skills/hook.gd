class_name Hook
extends Skill
## The light-whip cast out in a line: the first enemy caught (two with Double Hook) is dragged to your feet and
## stunned. Drag the Light feeds the lantern; Snap cracks a free Sunlash on the catch.

const LINE_W: float = 16.0
const PULL: float = 420.0


func reach() -> float:
	return float(data["range"]) * (1.0 + val("range_pct") / 100.0)


func use(target: Vector2) -> void:
	var dir: Vector2 = (target - p.global_position).normalized()
	var from: Vector2 = p.global_position + Vector2(0, -18)
	WhipFx.lash(fx(), from, p.lantern_pos(), dir, reach(), 4.0, false, true)
	Audio.sfx("crack", -6.0, 0.8)
	var caught: Array[Enemy] = _in_line(dir).slice(0, 2 if rank("double_hook") > 0 else 1)
	for e: Enemy in caught:
		Combat.hit_enemy(e, roll(float(data["damage_pct"])), opts({"dir": -dir, "more": 1.0 + val("damage_pct") / 100.0,
			"stun": float(data["stun"]), "knockback": 0.0, "heavy": true}))
		if is_instance_valid(e) and not e.dead and e.rank != "boss":
			e.pull_toward(p.global_position, PULL)
		p.light.add(val("light"))
		if rank("snap") > 0:
			(p.skills.skill("sunlash") as Sunlash).crack_at(e)


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
	var r: Vector2 = shown_range(float(data["damage_pct"]))
	return [["Reach %d px, %d-%d, stuns %.1f s, drags to you" % [roundi(reach()), r.x, r.y, float(data["stun"])], UiDraw.TEXT]]
