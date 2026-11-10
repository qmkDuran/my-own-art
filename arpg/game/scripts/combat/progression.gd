class_name Progression
extends RefCounted
## Experience and the two point types:
## - skill points (per level): the mastery bar (unlocks skill tiers, adds stats), skill ranks and skill modifiers;
## - stars (1 per level after the first, +1 per answered prayer): the Hosts, groups of stars (Isa 40:26).

signal leveled(level: int)
signal changed

var level: int = 1
var xp: float = 0.0
var mastery: int = 0
var ranks: Dictionary = {}            # skill id -> rank
var mods: Array[String] = []          # "skill.mod"
var stars: Dictionary = {}            # group id -> stars taken (in order)
var bonus_stars: int = 0
var _spent: int = 0


func _init() -> void:
	if GameData.skills.is_empty():
		return
	var start: Dictionary = GameData.skills["start"]
	mastery = int(start["mastery"])
	for s: String in start["ranks"]:
		ranks[s] = int(start["ranks"][s])
	_spent = mastery
	for s: String in ranks:
		_spent += int(ranks[s])


static func xp_for(lvl: int) -> float:
	return roundf(40.0 * pow(float(lvl), 1.55))


func add_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_for(level):
		xp -= xp_for(level)
		level += 1
		leveled.emit(level)
	changed.emit()


# ------------------------------------------------------------------ skills
func skill_points() -> int:
	return int(GameData.skills["skill_points_per_level"]) * level - _spent


func tier_open(tier: int) -> bool:
	return mastery >= int(GameData.skills["mastery"]["tiers"][tier])


func rank(skill: String) -> int:
	return int(ranks.get(skill, 0))


func has_mod(skill: String, mod: String) -> bool:
	return mods.has(skill + "." + mod)


func add_mastery() -> bool:
	if skill_points() <= 0 or mastery >= int(GameData.skills["mastery"]["max"]):
		return false
	mastery += 1
	_spend()
	return true


func add_rank(skill: String) -> bool:
	var s: Dictionary = GameData.skill(skill)
	if skill_points() <= 0 or not tier_open(int(s["tier"])) or rank(skill) >= int(GameData.skills["max_rank"]):
		return false
	ranks[skill] = rank(skill) + 1
	_spend()
	return true


func add_mod(skill: String, mod: String) -> bool:
	if skill_points() <= 0 or rank(skill) < 1 or has_mod(skill, mod):
		return false
	mods.append(skill + "." + mod)
	_spend()
	return true


func _spend() -> void:
	_spent += 1
	changed.emit()


## Damage factor from a skill's rank (rank 1 = 1.0).
func rank_mult(skill: String) -> float:
	return 1.0 + float(GameData.skills["rank_bonus"]) * float(maxi(0, rank(skill) - 1))


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


## Stat dictionaries from mastery, stars taken and completed groups.
func passive_stats() -> Array:
	var out: Array = []
	var per: Dictionary = GameData.skills["mastery"]["per_point"]
	var m: Dictionary = {}
	for k: String in per:
		m[k] = float(per[k]) * float(mastery)
	out.append(m)
	for g: String in stars:
		var grp: Dictionary = GameData.hosts["groups"][g]
		for i: int in int(stars[g]):
			out.append(grp["stars"][i]["stats"])
		if group_done(g):
			out.append(grp["bonus"])
	return out
