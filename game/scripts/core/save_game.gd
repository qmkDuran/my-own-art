class_name SaveGame
extends RefCounted
## Progress kept between sessions (user://lanternfall_save.json, format 2): the Session — the character (build,
## bag, Light, life, tonics, loot filter), the campaign (flags, quests, what people said), every visited zone's
## state (lit lamps, opened chests, read notes, bosses beaten) — plus the zone you stand in and where. Not used by
## tests or the demo (--smoke, --demo, --fresh, --shots).

const PATH: String = "user://lanternfall_save.json"
const VERSION: int = 2
const MATCH_DIST: float = 2.0


static func enabled() -> bool:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	return not (args.has("--demo") or args.has("--smoke") or args.has("--fresh") or args.has("--shots"))


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func erase() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


## Everything as one dictionary (the Session after capturing this zone).
static func snapshot(g: Game) -> Dictionary:
	Session.capture(g)
	Session.position = g.player.global_position
	var d: Dictionary = Session.to_dict()
	d["version"] = VERSION
	return d


static func write(g: Game) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(snapshot(g)))


## Loads the save into Session (call before entering the game scene). False if there is none or it is old.
static func load_session() -> bool:
	if not exists():
		return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not d is Dictionary or int(d.get("version", 0)) != VERSION:
		return false
	Session.from_dict(d)
	return true


static func apply_character(g: Game, c: Dictionary) -> void:
	var p: Player = g.player
	p.prog.from_dict(c["prog"])
	p.inv.from_dict(c["inv"])
	p.refresh_stats()
	p.light.value = float(c.get("light", p.light.value))
	p.life = clampf(float(c.get("life", p.stats.max_life())), 1.0, p.stats.max_life())
	p.tonics = int(c.get("tonics", p.max_tonics()))
	LootFilter.from_dict(c.get("filter", {}))


static func apply_zone(g: Game, st: Dictionary) -> void:
	g.flags = st.get("flags", {})
	g.flags.erase("boss")
	var lit: Array = st.get("lamps", [])
	for i: int in mini(g.lamps.size(), lit.size()):
		if bool(lit[i]):
			g.lamps[i].set_lit(true)
	_restore_opened(g, st.get("opened", []))


## Positions of things already used in this zone: opened chests, people met, notes read.
static func opened(g: Game) -> Array:
	var out: Array = []
	for n: Node in g.get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		var done: bool = (it is Chest and (it as Chest).opened) or (it is Npc and (it as Npc).talked > 0) \
			or (it is LoreObject and (it as LoreObject).read)
		if done:
			out.append([it.global_position.x, it.global_position.y])
	return out


static func _restore_opened(g: Game, done: Array) -> void:
	for n: Node in g.get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		for c: Array in done:
			if it.global_position.distance_to(Vector2(float(c[0]), float(c[1]))) > MATCH_DIST:
				continue
			if it is Chest:
				(it as Chest).open(g, false)
			elif it is Npc:
				(it as Npc).talked = 1
			elif it is LoreObject:
				(it as LoreObject).read = true
