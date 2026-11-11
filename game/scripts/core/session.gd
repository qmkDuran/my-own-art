class_name Session
extends RefCounted
## What outlives one zone scene: which zone to play and from where we arrive, the character (build, bag, Light,
## life), the campaign (flags, quests), and each visited zone's state (lit lamps, opened chests, people met,
## bosses beaten). Zone changes and saving both go through here.

static var zone_id: String = ""
static var arrive_from: String = ""          ## the zone we came from ("" = saved position or a new game)
static var position: Vector2 = Vector2.INF   ## where to stand (from a save)
static var character: Dictionary = {}
static var campaign := Campaign.new()
static var zones: Dictionary = {}           ## zone id -> {lamps, opened, flags}
static var stash: Array = []                ## Fenn's lockers (shared by every visit), STASH_CELLS entries
static var establishing: bool = false      ## a new game: Tallow opens on the Great Lantern and pans down to you
static var arrive_at_lamp: bool = false     ## travelled by map: stand by the zone's first lit waylamp

const STASH_CELLS: int = 48


static func reset() -> void:
	zone_id = String(GameData.zones["start"])
	arrive_from = ""
	position = Vector2.INF
	character = {}
	campaign = Campaign.new()
	zones = {}
	stash = []
	stash.resize(STASH_CELLS)
	stash.fill({})
	arrive_at_lamp = false
	campaign.start("first_light")


static func zone_state(id: String) -> Dictionary:
	if not zones.has(id):
		zones[id] = {"lamps": [], "opened": [], "flags": {}}
	return zones[id]


## Leaves the current zone for another one: keeps everything, then loads the next scene.
static func travel(g: Game, to: String, by_map: bool = false) -> void:
	capture(g)
	arrive_from = "" if by_map else g.zone_id
	arrive_at_lamp = by_map
	zone_id = to
	position = Vector2.INF
	g.get_tree().change_scene_to_file("res://scenes/game.tscn")


static func capture(g: Game) -> void:
	var p: Player = g.player
	character = {"prog": p.prog.to_dict(), "inv": p.inv.to_dict(), "light": p.light.value, "life": p.life,
		"tonics": p.tonics, "filter": LootFilter.to_dict()}
	var st: Dictionary = zone_state(g.zone_id)
	st["lamps"] = g.lamps.map(func(l: Waylamp) -> bool: return l.lit)
	st["opened"] = SaveGame.opened(g)
	st["flags"] = g.flags


static func to_dict() -> Dictionary:
	return {"zone": zone_id, "position": [position.x, position.y], "character": character,
		"campaign": campaign.to_dict(), "zones": zones, "stash": stash}


static func from_dict(d: Dictionary) -> void:
	zone_id = String(d.get("zone", GameData.zones["start"]))
	var pos: Array = d.get("position", [INF, INF])
	position = Vector2(float(pos[0]), float(pos[1]))
	arrive_from = ""
	character = d.get("character", {})
	campaign = Campaign.new()
	campaign.from_dict(d.get("campaign", {}))
	zones = d.get("zones", {})
	stash = d.get("stash", [])
	stash.resize(STASH_CELLS)
	for i: int in STASH_CELLS:
		if stash[i] == null:
			stash[i] = {}
	arrive_at_lamp = false
