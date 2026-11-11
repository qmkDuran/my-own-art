class_name Skill
extends RefCounted
## One skill's rules and numbers. Subclasses implement use() and their own tooltip lines; the base gives level,
## specialisation values, cost, cooldown, cast time and damage rolls so every number has one source.

var id: String
var data: Dictionary
var p: Player


func setup(skill_id: String, player: Player) -> Skill:
	id = skill_id
	data = GameData.skill(skill_id)
	p = player
	return self


func level() -> int:
	return maxi(1, p.prog.skill_level(id))


func rank(node: String) -> int:
	return p.prog.node_rank(id, node)


func val(key: String) -> float:
	return p.prog.spec_val(id, key)


func is_spell() -> bool:
	return String(data["kind"]) == "spell"


func cost() -> float:
	return float(data.get("cost", 0.0))


func cooldown() -> float:
	return float(data.get("cooldown", 0.0)) * p.stats.cooldown_mult()


func speed_mult() -> float:
	var haste: float = (p.skills.skill("kindle") as Kindle).haste() if p.skills != null else 1.0
	return (p.stats.cast_speed_mult() if is_spell() else p.stats.attack_speed_mult()) * haste


func cast_time() -> float:
	return float(data.get("time", 0.0)) / speed_mult()


## The animation he plays to use it (sprites.json "lamplighter" anims); the skill lands on its "hit" frame.
func pose() -> String:
	return "cast" if is_spell() else "bolt1"


## Damage before increases: a spell's own base (grows per skill level) or the staff's damage, times pct.
func base_range(pct: float = 100.0) -> Vector2:
	var r: Vector2
	if is_spell():
		r = Vector2(float(data["base"][0]), float(data["base"][1])) * (1.0 + float(data["per_level_pct"]) / 100.0 * (level() - 1)) \
			+ Vector2.ONE * p.stats.v("added_sunfire")
	else:
		r = p.stats.staff_range()
	return r * pct / 100.0


## The range the tooltip shows: base x increased (before Blazing, Shrouded and crits, which depend on the moment).
func shown_range(pct: float = 100.0) -> Vector2:
	return (base_range(pct) * p.stats.increased(String(data["kind"]))).round()


func roll(pct: float = 100.0) -> float:
	var r: Vector2 = base_range(pct)
	return randf_range(r.x, r.y)


func opts(extra: Dictionary = {}) -> Dictionary:
	var o: Dictionary = {"kind": String(data["kind"]), "skill": id}
	o.merge(extra, true)
	o["more"] = float(o.get("more", 1.0)) * p.skills.dark_more()
	return o


func use(_target: Vector2) -> void:
	pass


## Extra tooltip rows (numbers that depend on the tree).
func info() -> Array:
	return []


func fx() -> Node2D:
	return Game.current.fx_layer


## Hits every enemy within `r` of `center` for `pct` of the base; returns how many were hit.
func hit_area(center: Vector2, r: float, pct: float, extra: Dictionary = {}) -> int:
	var hits: Array[Enemy] = enemies_in_arc(center, Vector2.RIGHT, r, 360.0)
	for e: Enemy in hits:
		var o: Dictionary = extra.duplicate()
		o["dir"] = e.global_position - center
		Combat.hit_enemy(e, roll(pct), opts(o))
	return hits.size()


## Enemies in a cone (or circle when arc >= 360) around a point.
func enemies_in_arc(center: Vector2, dir: Vector2, reach: float, arc_deg: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for n: Node in p.get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		var d: Vector2 = e.global_position - center
		if d.length() - e.radius > reach:
			continue
		if arc_deg < 360.0 and d.length() > e.radius and absf(dir.angle_to(d)) > deg_to_rad(arc_deg) * 0.5:
			continue
		out.append(e)
	return out
