class_name Progression
extends RefCounted
## Character level and experience, passive points (base tree + mastery), and every skill's own level, experience
## and specialisation points. Skills are learned by level (data: learn_level) and take the first free hotbar slot.

signal changed
signal leveled(level: int)
signal skill_leveled(skill: String, level: int)
signal learned(skill: String)

const LEARN: Dictionary = {"sunlash": 1, "flare": 1, "lantern_toss": 2, "moth_swarm": 3, "kindle": 4, "hook": 5, "eclipse": 6,
	"glass_ward": 7, "cinder_rain": 9, "noon": 10, "wick_trap": 11, "lull": 12}

var level: int = 1
var xp: float = 0.0
var passives: Dictionary = {}       ## node id -> rank
var mastery: String = ""
var skills: Dictionary = {}         ## skill id -> {level, xp, nodes: {id: rank}}
var slots: Dictionary = {"lmb": "", "rmb": "", "q": "", "w": "", "e": "", "r": ""}
var specialised: Array = []         ## skills in specialisation slots (only these level up and take points)


func _init() -> void:
	_learn_up_to(level)


# ------------------------------------------------------------------ character level
func xp_to_next(l: int = level) -> float:
	return float(GameData.player["xp_base"]) * pow(l, float(GameData.player["xp_exponent"]))


func add_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next() and level < int(GameData.player["level_cap"]):
		xp -= xp_to_next()
		level += 1
		_learn_up_to(level)
		leveled.emit(level)
	for s: String in specialised:
		_add_skill_xp(s, amount)
	changed.emit()


func _learn_up_to(l: int) -> void:
	for s: String in LEARN:
		if int(LEARN[s]) <= l and not skills.has(s):
			skills[s] = {"level": 1, "xp": 0.0, "nodes": {}}
			_auto_slot(s)
			specialise(s)
			learned.emit(s)


func _auto_slot(s: String) -> void:
	var prefer: Dictionary = {"sunlash": "lmb", "flare": "rmb", "lantern_toss": "q", "moth_swarm": "w", "eclipse": "e", "noon": "r"}
	var want: String = String(prefer.get(s, ""))
	if want != "" and slots[want] == "":
		slots[want] = s
		return
	for k: String in InputSetup.SLOTS:
		if slots[k] == "":
			slots[k] = s
			return


func slotted() -> Array[String]:
	var out: Array[String] = []
	for k: String in slots:
		if slots[k] != "" and not out.has(slots[k]):
			out.append(slots[k])
	return out


func set_slot(key: String, skill: String) -> void:
	for k: String in slots:
		if slots[k] == skill:
			slots[k] = slots[key]
	slots[key] = skill
	changed.emit()


# ------------------------------------------------------------------ specialisation slots
## Slots open by level (player.json skill_slot_levels): 5 in all.
func spec_slots() -> int:
	return (GameData.player["skill_slot_levels"] as Array).filter(func(l: Variant) -> bool: return int(l) <= level).size()


func is_specialised(s: String) -> bool:
	return specialised.has(s)


func can_specialise(s: String) -> bool:
	return skills.has(s) and not specialised.has(s) and specialised.size() < spec_slots() and not GameData.skill(s)["nodes"].is_empty()


func specialise(s: String) -> bool:
	if not can_specialise(s):
		return false
	specialised.append(s)
	changed.emit()
	return true


## Leaving a slot forgets the skill's training: back to level 1, tree cleared.
func forget(s: String) -> void:
	if specialised.has(s):
		specialised.erase(s)
		skills[s]["level"] = 1
		skills[s]["xp"] = 0.0
		skills[s]["nodes"] = {}
		changed.emit()


# ------------------------------------------------------------------ skills
func skill_level(s: String) -> int:
	return int(skills.get(s, {}).get("level", 0))


func skill_xp_to_next(l: int) -> float:
	return float(GameData.player["skill_xp_base"]) * pow(l, float(GameData.player["skill_xp_exponent"]))


func _add_skill_xp(s: String, amount: float) -> void:
	var d: Dictionary = skills[s]
	if GameData.skill(s)["nodes"].is_empty():
		return
	d["xp"] = float(d["xp"]) + amount
	while float(d["xp"]) >= skill_xp_to_next(int(d["level"])) and int(d["level"]) < int(GameData.player["skill_level_cap"]):
		d["xp"] = float(d["xp"]) - skill_xp_to_next(int(d["level"]))
		d["level"] = int(d["level"]) + 1
		skill_leveled.emit(s, int(d["level"]))


func node_rank(s: String, node: String) -> int:
	return int(skills.get(s, {}).get("nodes", {}).get(node, 0))


func spec_spent(s: String) -> int:
	var n: int = 0
	for k: String in skills.get(s, {}).get("nodes", {}):
		n += int(skills[s]["nodes"][k])
	return n


func spec_points(s: String) -> int:
	return skill_level(s) - spec_spent(s)


func spec_node(s: String, node: String) -> Dictionary:
	for n: Dictionary in GameData.skill(s)["nodes"]:
		if n["id"] == node:
			return n
	return {}


## Why a node cannot take a point ("" if it can).
func spec_block(s: String, node: String) -> String:
	var n: Dictionary = spec_node(s, node)
	if not skills.has(s):
		return "Skill not learned"
	if not specialised.has(s):
		return "Specialise this skill first (a free slot is needed)"
	if node_rank(s, node) >= int(n["max"]):
		return "Maxed"
	if spec_points(s) <= 0:
		return "No points (the skill gains one per level)"
	if spec_spent(s) < int(n["req"]):
		return "Needs %d points in this tree" % int(n["req"])
	if n.has("parent") and node_rank(s, String(n["parent"])) == 0:
		return "Needs %s first" % String(spec_node(s, String(n["parent"]))["name"])
	return ""


func add_spec(s: String, node: String) -> bool:
	if spec_block(s, node) != "":
		return false
	skills[s]["nodes"][node] = node_rank(s, node) + 1
	changed.emit()
	return true


## Refund one point (the most recent tier first is enforced by requirements staying met).
func remove_spec(s: String, node: String) -> bool:
	if node_rank(s, node) == 0:
		return false
	skills[s]["nodes"][node] = node_rank(s, node) - 1
	if not _spec_valid(s):
		skills[s]["nodes"][node] = node_rank(s, node) + 1
		return false
	changed.emit()
	return true


func _spec_valid(s: String) -> bool:
	for n: Dictionary in GameData.skill(s)["nodes"]:
		var r: int = node_rank(s, String(n["id"]))
		if r == 0:
			continue
		var spent_before: int = spec_spent(s) - r
		if spent_before < int(n["req"]) or (n.has("parent") and node_rank(s, String(n["parent"])) == 0):
			return false
	return true


## Sum of a value over a skill's allocated nodes (vals are per point).
func spec_val(s: String, key: String) -> float:
	var total: float = 0.0
	for n: Dictionary in GameData.skill(s)["nodes"]:
		total += float(n["vals"].get(key, 0.0)) * node_rank(s, String(n["id"]))
	return total


func has_node(s: String, node: String) -> bool:
	return node_rank(s, node) > 0


# ------------------------------------------------------------------ passives
func passive_points() -> int:
	var spent: int = 0
	for k: String in passives:
		spent += int(passives[k])
	return (level - 1) - spent


func tree_spent(tree: String) -> int:
	var n: int = 0
	for node: Dictionary in GameData.passives["trees"][tree]["nodes"]:
		n += int(passives.get(node["id"], 0))
	return n


func tree_open(tree: String) -> bool:
	if not GameData.passives["trees"][tree].get("mastery", false):
		return true
	if tree == mastery:
		return true
	return mastery != "" and tree_spent("lamplighter") >= int(GameData.passives["unlock_other_masteries"])


func passive_node(id: String) -> Dictionary:
	for tree: String in GameData.passives["trees"]:
		for n: Dictionary in GameData.passives["trees"][tree]["nodes"]:
			if n["id"] == id:
				var out: Dictionary = n.duplicate()
				out["tree"] = tree
				return out
	return {}


func passive_block(id: String) -> String:
	var n: Dictionary = passive_node(id)
	if not tree_open(String(n["tree"])):
		return "Choose this mastery (level %d)" % int(GameData.player["mastery_level"]) if mastery == "" else "Needs 20 points in Lamplighter"
	if int(passives.get(id, 0)) >= int(n["max"]):
		return "Maxed"
	if passive_points() <= 0:
		return "No passive points (one per level)"
	if tree_spent(String(n["tree"])) < int(n["req"]):
		return "Needs %d points in %s" % [int(n["req"]), GameData.passives["trees"][n["tree"]]["name"]]
	return ""


func add_passive(id: String) -> bool:
	if passive_block(id) != "":
		return false
	passives[id] = int(passives.get(id, 0)) + 1
	changed.emit()
	return true


func remove_passive(id: String) -> bool:
	if int(passives.get(id, 0)) == 0:
		return false
	passives[id] = int(passives[id]) - 1
	var tree: String = String(passive_node(id)["tree"])
	for n: Dictionary in GameData.passives["trees"][tree]["nodes"]:
		if int(passives.get(n["id"], 0)) > 0 and tree_spent(tree) - int(passives[n["id"]]) < int(n["req"]):
			passives[id] = int(passives[id]) + 1
			return false
	changed.emit()
	return true


func refund_passives() -> void:
	passives = {}
	changed.emit()


func refund_skill(s: String) -> void:
	if skills.has(s):
		skills[s]["nodes"] = {}
		changed.emit()


func can_choose_mastery() -> bool:
	return mastery == "" and level >= int(GameData.player["mastery_level"])


func choose_mastery(tree: String) -> bool:
	if not can_choose_mastery() or not GameData.passives["trees"][tree].get("mastery", false):
		return false
	mastery = tree
	changed.emit()
	return true


## Rules changed by allocated keystones (read by the code that the rule touches).
func passive_rules() -> Array[String]:
	var out: Array[String] = []
	for id: String in passives:
		var n: Dictionary = passive_node(id)
		if int(passives[id]) > 0 and n.get("keystone", false):
			out.append(String(n["rule"]))
	return out


## Stats granted by passives and the mastery bonus.
func passive_stats() -> Dictionary:
	var out: Dictionary = {}
	for id: String in passives:
		var r: int = int(passives[id])
		if r == 0:
			continue
		var n: Dictionary = passive_node(id)
		for k: String in n["stats"]:
			out[k] = float(out.get(k, 0.0)) + float(n["stats"][k]) * r
	if mastery != "":
		var bonus: Dictionary = GameData.passives["trees"][mastery]["bonus"]
		for k: String in bonus:
			out[k] = float(out.get(k, 0.0)) + float(bonus[k])
	return out


# ------------------------------------------------------------------ save
func to_dict() -> Dictionary:
	return {"level": level, "xp": xp, "passives": passives, "mastery": mastery, "skills": skills, "slots": slots,
		"specialised": specialised}


func from_dict(d: Dictionary) -> void:
	level = int(d.get("level", 1))
	xp = float(d.get("xp", 0.0))
	passives = d.get("passives", {})
	mastery = String(d.get("mastery", ""))
	skills = d.get("skills", {})
	slots = d.get("slots", slots)
	specialised = d.get("specialised", [])
	for s: String in skills:
		skills[s]["level"] = int(skills[s]["level"])
	changed.emit()
