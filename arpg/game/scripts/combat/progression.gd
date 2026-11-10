class_name Progression
extends RefCounted
## Experience and Michael's build:
## - skill points (per level) go into the bars of up to two masteries (each opens tiers of its skills and adds stats),
##   into skill ranks and into skill modifiers; the pair of masteries gives a class title;
## - attribute points (per level): Might, Agility, Spirit;
## - stars (1 per level after the first, +1 per answered prayer): the Hosts, groups of stars (Isa 40:26).
## Respec refunds skill and attribute points (masteries stay chosen). Serialised by SaveGame.

signal leveled(level: int)
signal changed

var level: int = 1
var xp: float = 0.0
var masteries: Array[String] = []          # chosen, in order
var mastery_points: Dictionary = {}        # mastery -> points
var ranks: Dictionary = {}                 # skill -> rank
var mods: Array[String] = []               # "skill.mod"
var attributes: Dictionary = {"might": 0, "agility": 0, "spirit": 0}
var slots: Dictionary = {}                 # key ("RMB", "Q"...) -> skill
var stars: Dictionary = {}                 # group -> stars taken (in order)
var bonus_stars: int = 0


func _init() -> void:
	if not GameData.skills.is_empty():
		_start()


func _start() -> void:
	var st: Dictionary = GameData.skills["start"]
	masteries.assign(st["masteries"])
	mastery_points = st["mastery_points"].duplicate()
	ranks = st["ranks"].duplicate()


static func xp_for(lvl: int) -> float:
	return roundf(40.0 * pow(float(lvl), 1.55))


func add_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_for(level):
		xp -= xp_for(level)
		level += 1
		leveled.emit(level)
	changed.emit()


# ------------------------------------------------------------------ masteries and skills
func skill_points() -> int:
	var spent: int = mods.size()
	for m: String in mastery_points:
		spent += int(mastery_points[m])
	for s: String in ranks:
		spent += int(ranks[s])
	return int(GameData.skills["skill_points_per_level"]) * level - spent


func can_choose_mastery() -> bool:
	return masteries.size() < 2 and (masteries.is_empty() or level >= int(GameData.skills["second_mastery_level"]))


func choose_mastery(id: String) -> bool:
	if not can_choose_mastery() or masteries.has(id):
		return false
	masteries.append(id)
	mastery_points[id] = 0
	changed.emit()
	return true


func class_title() -> String:
	if masteries.size() < 2:
		return String(GameData.skills["masteries"][masteries[0]]["name"]) if not masteries.is_empty() else ""
	var key: Array = masteries.duplicate()
	key.sort()
	return String(GameData.skills["classes"].get("+".join(key), ""))


func mastery_of(skill: String) -> String:
	for m: String in GameData.skills["masteries"]:
		for e: Array in GameData.skills["masteries"][m]["skills"]:
			if e[0] == skill:
				return m
	return ""


func tier_of(skill: String) -> int:
	for e: Array in GameData.skills["masteries"][mastery_of(skill)]["skills"]:
		if e[0] == skill:
			return int(e[1])
	return 0


func skill_open(skill: String) -> bool:
	var m: String = mastery_of(skill)
	return masteries.has(m) and int(mastery_points.get(m, 0)) >= int(GameData.skills["tiers"][tier_of(skill)])


func rank(skill: String) -> int:
	return int(ranks.get(skill, 0))


func has_mod(skill: String, mod: String) -> bool:
	return mods.has(skill + "." + mod)


func add_mastery(m: String) -> bool:
	if skill_points() <= 0 or not masteries.has(m) or int(mastery_points.get(m, 0)) >= int(GameData.skills["max_mastery"]):
		return false
	mastery_points[m] = int(mastery_points.get(m, 0)) + 1
	changed.emit()
	return true


func add_rank(skill: String) -> bool:
	if skill_points() <= 0 or not skill_open(skill) or rank(skill) >= int(GameData.skills["max_rank"]):
		return false
	ranks[skill] = rank(skill) + 1
	if ranks[skill] == 1 and skill != "strike":
		_auto_slot(skill)
	changed.emit()
	return true


func add_mod(skill: String, mod: String) -> bool:
	if skill_points() <= 0 or rank(skill) < 1 or has_mod(skill, mod):
		return false
	mods.append(skill + "." + mod)
	changed.emit()
	return true


## A newly learned skill takes the first free key (RMB, Q, W, E, R).
func _auto_slot(skill: String) -> void:
	for k: String in GameData.skills["slot_keys"]:
		if not slots.has(k):
			slots[k] = skill
			return


## Move a learned skill to the next key (swapping with whatever is there).
func cycle_slot(skill: String) -> void:
	var keys: Array = GameData.skills["slot_keys"]
	var cur: String = ""
	for k: String in slots:
		if slots[k] == skill:
			cur = k
	var next: String = keys[(keys.find(cur) + 1) % keys.size()] if cur != "" else keys[0]
	var other: Variant = slots.get(next, null)
	slots[next] = skill
	if cur != "":
		if other != null:
			slots[cur] = other
		else:
			slots.erase(cur)
	changed.emit()


func slot_of(skill: String) -> String:
	for k: String in slots:
		if slots[k] == skill:
			return k
	return ""


func rank_mult(skill: String) -> float:
	return 1.0 + float(GameData.skills["rank_bonus"]) * float(maxi(0, rank(skill) - 1))


# ------------------------------------------------------------------ attributes
func attribute_points() -> int:
	var spent: int = 0
	for a: String in attributes:
		spent += int(attributes[a])
	return int(GameData.skills["attribute_points_per_level"]) * (level - 1) - spent


func add_attribute(a: String) -> bool:
	if attribute_points() <= 0:
		return false
	attributes[a] = int(attributes[a]) + 1
	changed.emit()
	return true


## Refund every skill and attribute point; masteries stay chosen at 0, Strike keeps rank 1.
func respec() -> void:
	for m: String in masteries:
		mastery_points[m] = 1 if m == masteries[0] else 0
	ranks = {"strike": 1}
	mods.clear()
	slots.clear()
	for a: String in attributes:
		attributes[a] = 0
	changed.emit()


# ------------------------------------------------------------------ stars (the Hosts)
func star_points() -> int:
	var taken: int = 0
	for g: String in stars:
		taken += int(stars[g])
	return (level - 1) + bonus_stars - taken


func group_done(g: String) -> bool:
	return int(stars.get(g, 0)) >= GameData.hosts["groups"][g]["stars"].size()


func group_open(g: String) -> bool:
	for r: String in GameData.hosts["groups"][g]["requires"]:
		if not group_done(r):
			return false
	return true


func take_star(g: String) -> bool:
	if star_points() <= 0 or not group_open(g) or group_done(g):
		return false
	stars[g] = int(stars.get(g, 0)) + 1
	changed.emit()
	return true


func grant_star() -> void:
	bonus_stars += 1
	changed.emit()


## Stat dictionaries from masteries, attributes, stars taken and completed groups.
func passive_stats() -> Array:
	var out: Array = []
	for m: String in masteries:
		var per: Dictionary = GameData.skills["masteries"][m]["per_point"]
		var st: Dictionary = {}
		for k: String in per:
			st[k] = float(per[k]) * float(mastery_points.get(m, 0))
		out.append(st)
	out.append(attributes.duplicate())
	for g: String in stars:
		var grp: Dictionary = GameData.hosts["groups"][g]
		for i: int in int(stars[g]):
			out.append(grp["stars"][i]["stats"])
		if group_done(g):
			out.append(grp["bonus"])
	return out


# ------------------------------------------------------------------ save data
func to_dict() -> Dictionary:
	return {"level": level, "xp": xp, "masteries": masteries, "mastery_points": mastery_points, "ranks": ranks, "mods": mods,
		"attributes": attributes, "slots": slots, "stars": stars, "bonus_stars": bonus_stars}


func from_dict(d: Dictionary) -> void:
	level = int(d["level"])
	xp = float(d["xp"])
	masteries.assign(d["masteries"])
	mastery_points = d["mastery_points"]
	ranks = d["ranks"]
	mods.assign(d["mods"])
	attributes = d["attributes"]
	slots = d["slots"]
	stars = d["stars"]
	bonus_stars = int(d["bonus_stars"])
	changed.emit()
