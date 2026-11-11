class_name Objectives
extends RefCounted
## The tracker's lines (top-left) and the objective marker, from the campaign's active quests: the main quest
## first, then side quests. A goal in another zone points to the exit on the way there.

const MAX_QUESTS: int = 3


static func lines(_g: Game) -> Array:
	var c: Campaign = Session.campaign
	var out: Array = []
	for id: String in c.active().slice(0, MAX_QUESTS):
		var q: Dictionary = GameData.quests[id]
		var st: Dictionary = c.step(id)
		var goal: Array = st["goal"]
		var count: String = " (%d/%d)" % [int(c.quests[id]["count"]), int(goal[2])] if goal.size() > 2 else ""
		out.append([String(q["title"]), UiDraw.GOLD if bool(q["main"]) else Color("9fc4ff")])
		out.append(["  " + String(st["text"]) + count, UiDraw.TEXT])
	if out.is_empty():
		out.append(["Explore, or rest in Tallow.", UiDraw.DIM])
	return out


## Where the main goal is in this zone (INF if nothing to point at).
static func target(g: Game) -> Vector2:
	var c: Campaign = Session.campaign
	var act: Array[String] = c.active()
	if act.is_empty():
		return Vector2.INF
	var t: Dictionary = c.step(act[0]).get("target", {})
	if t.is_empty():
		return Vector2.INF
	if String(t["zone"]) != g.zone_id:
		return _exit_toward(g, String(t["zone"]))
	return place(g, String(t["at"]))


static func place(g: Game, at: String) -> Vector2:
	if at == "circle":
		return g.layout.circle_center()
	if at.begins_with("npc:"):
		for n: Node in g.get_tree().get_nodes_in_group("interactables"):
			if n is Npc and (n as Npc).npc_id == at.substr(4):
				return (n as Npc).global_position
		return Vector2.INF
	if at.begins_with("role:"):
		var cl: Dictionary = g.layout.clearing_of_role(at.substr(5))
		return g.layout.center_of(cl["center"]) if not cl.is_empty() else Vector2.INF
	if at == "lamp":
		return _nearest_unlit(g)
	return Vector2.INF


static func _nearest_unlit(g: Game) -> Vector2:
	var best := Vector2.INF
	for l: Waylamp in g.lamps:
		if not l.lit and l.global_position.distance_to(g.player.global_position) < best.distance_to(g.player.global_position):
			best = l.global_position
	return best


## The exit to take toward `zone` (breadth-first over the zone links).
static func _exit_toward(g: Game, zone: String) -> Vector2:
	var hop: String = next_hop(g.zone_id, zone)
	for e: ZoneExit in g.exits:
		if e.to == hop:
			return e.global_position
	return Vector2.INF


static func next_hop(from: String, to: String) -> String:
	var prev: Dictionary = {from: ""}
	var q: Array[String] = [from]
	while not q.is_empty():
		var z: String = q.pop_front()
		if z == to:
			break
		for n: String in GameData.zone(z)["links"]:
			if not prev.has(n):
				prev[n] = z
				q.append(n)
	var step: String = to
	while prev.has(step) and String(prev[step]) != from and String(prev[step]) != "":
		step = prev[step]
	return step
