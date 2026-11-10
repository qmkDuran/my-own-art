class_name SaveGame
extends RefCounted
## Progress kept between sessions in user://: Michael's build (level, masteries, ranks, modifiers, attributes, keys,
## stars), the inventory, found waystones, opened chests and answered prayers. Written every few seconds when
## something changed and on quit; not used by --demo, --smoke or --fresh.

const PATH: String = "user://great_prince_save.json"
const VERSION: int = 1


static func enabled() -> bool:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	return not (args.has("--demo") or args.has("--smoke") or args.has("--fresh"))


static func write(g: Game) -> void:
	var data := {
		"version": VERSION,
		"prog": g.michael.prog.to_dict(),
		"inv": g.michael.inv.to_dict(),
		"stones": g.stones.map(func(s: Interactable) -> bool: return s.opened),
		"chests": g.get_tree().get_nodes_in_group("interactables").filter(func(i: Interactable) -> bool: return i.is_chest() and i.opened)
			.map(func(i: Interactable) -> Array: return [i.global_position.x, i.global_position.y]),
		"prayers": g.objective.points.map(func(p: Dictionary) -> int: return int(p["state"] == PrayerObjective.STATE_ANSWERED)),
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))


static func read(g: Game) -> bool:
	if not FileAccess.file_exists(PATH):
		return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not d is Dictionary or int(d.get("version", 0)) != VERSION:
		return false
	g.michael.prog.from_dict(d["prog"])
	g.michael.inv.from_dict(d["inv"])
	for i: int in mini(g.stones.size(), d["stones"].size()):
		if bool(d["stones"][i]):
			(g.stones[i] as Interactable).notice_michael_force()
	for c: Array in d["chests"]:
		for n: Node in g.get_tree().get_nodes_in_group("interactables"):
			var it := n as Interactable
			if it.is_chest() and it.global_position.distance_to(Vector2(float(c[0]), float(c[1]))) < 2.0:
				it.mark_opened()
	for i: int in mini(g.objective.points.size(), d["prayers"].size()):
		if int(d["prayers"][i]) == 1:
			g.objective.points[i]["state"] = PrayerObjective.STATE_ANSWERED
	g.michael.refresh_stats()
	g.michael.life = g.michael.stats.v("life")
	return true
