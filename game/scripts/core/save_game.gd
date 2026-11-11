class_name SaveGame
extends RefCounted
## Progress kept between sessions (user://lanternfall_save.json): the build (levels, passives, mastery, skill
## levels and trees, hotbar), the bag and equipment, the Light, lit waylamps, opened chests, people talked to,
## story flags, and where you stand. Not used by tests or the demo (--smoke, --demo, --fresh).

const PATH: String = "user://lanternfall_save.json"
const VERSION: int = 1
const MATCH_DIST: float = 2.0


static func enabled() -> bool:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	return not (args.has("--demo") or args.has("--smoke") or args.has("--fresh") or args.has("--shots"))


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func erase() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


static func snapshot(g: Game) -> Dictionary:
	var p: Player = g.player
	return {
		"version": VERSION, "seed": g.layout.seed,
		"prog": p.prog.to_dict(), "inv": p.inv.to_dict(),
		"light": p.light.value, "life": p.life, "pos": [p.global_position.x, p.global_position.y],
		"respawn": [p.respawn_at.x, p.respawn_at.y], "flags": g.flags,
		"lamps": g.lamps.map(func(l: Waylamp) -> bool: return l.lit),
		"opened": _opened(g),
	}


static func _opened(g: Game) -> Array:
	var out: Array = []
	for n: Node in g.get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		var done: bool = (it is Chest and (it as Chest).opened) or (it is Npc and (it as Npc).talked > 0) \
			or (it is LoreObject and (it as LoreObject).read)
		if done:
			out.append([it.global_position.x, it.global_position.y])
	return out


static func write(g: Game) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(snapshot(g)))


static func read(g: Game) -> bool:
	if not exists():
		return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not d is Dictionary or int(d.get("version", 0)) != VERSION:
		return false
	apply(g, d)
	return true


static func apply(g: Game, d: Dictionary) -> void:
	var p: Player = g.player
	p.prog.from_dict(d["prog"])
	p.inv.from_dict(d["inv"])
	p.refresh_stats()
	p.light.value = float(d.get("light", p.light.value))
	p.life = minf(float(d.get("life", p.stats.max_life())), p.stats.max_life())
	p.global_position = Vector2(float(d["pos"][0]), float(d["pos"][1]))
	p.respawn_at = Vector2(float(d["respawn"][0]), float(d["respawn"][1]))
	g.flags = d.get("flags", {})
	g.flags.erase("boss")
	for i: int in mini(g.lamps.size(), (d["lamps"] as Array).size()):
		if bool(d["lamps"][i]):
			g.lamps[i].set_lit(true)
	_restore_opened(g, d["opened"])
	g.camera.reset_smoothing()


static func _restore_opened(g: Game, opened: Array) -> void:
	for n: Node in g.get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		for c: Array in opened:
			if it.global_position.distance_to(Vector2(float(c[0]), float(c[1]))) > MATCH_DIST:
				continue
			if it is Chest:
				(it as Chest).open(g, false)
			elif it is Npc:
				(it as Npc).talked = 1
			elif it is LoreObject:
				(it as LoreObject).read = true
