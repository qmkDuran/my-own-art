class_name SaveSystem
extends RefCounted
## Saving and loading the game to user://save.json (one slot).

const PATH: String = "user://save.json"
const VERSION: int = 1


static func has_save() -> bool:
	return FileAccess.file_exists(PATH)


static func save() -> void:
	var f: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(snapshot(), "\t"))


static func snapshot() -> Dictionary:
	var g: GameState = Game
	return {
		"version": VERSION, "party": g.party.map(func(c: Creature) -> Dictionary: return c.to_dict()),
		"bag": g.bag.counts, "seen": g.journal.seen, "befriended": g.journal.befriended, "flags": g.flags,
		"coins": g.coins, "wild_friends": g.wild_friends, "map": g.map_id, "cell": [g.cell.x, g.cell.y], "facing": [g.facing.x, g.facing.y],
		"heal_stage": g.heal_stage,
	}


static func load_game() -> bool:
	if not has_save():
		return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not d is Dictionary:
		return false
	restore(d as Dictionary)
	return true


static func restore(d: Dictionary) -> void:
	var g: GameState = Game
	g.party.clear()
	for c: Dictionary in d["party"]:
		g.party.append(Creature.from_dict(c))
	g.bag = Bag.new()
	for id: String in d["bag"]:
		g.bag.add(id, int(d["bag"][id]))
	g.journal = Journal.new()
	g.journal.seen = d["seen"]
	g.journal.befriended = d["befriended"]
	g.flags = d["flags"]
	g.coins = int(d["coins"])
	g.wild_friends = int(d.get("wild_friends", 0))
	g.map_id = String(d["map"])
	g.cell = Vector2i(int(d["cell"][0]), int(d["cell"][1]))
	g.facing = Vector2i(int(d["facing"][0]), int(d["facing"][1]))
	g.heal_stage = int(d["heal_stage"])
