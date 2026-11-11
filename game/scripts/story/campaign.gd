class_name Campaign
extends RefCounted
## The story's state across every zone: global flags and quests. Things that happen are reported as events
## (enter_zone, talk, boss_seen, boss_down, lamp_lit, read, flag); a quest's current step completes when its goal
## event arrives (counting where the goal has a count), and the quest moves on, rewards paid, next quest started.

signal changed
signal quest_done(id: String)

var flags: Dictionary = {}
var quests: Dictionary = {}           ## id -> {step: int, count: int, done: bool}
var rewards: Array[Dictionary] = []   ## rewards waiting for the session to pay out
var said: Dictionary = {}             ## person -> topics already said
var kills: Dictionary = {}            ## enemy kind -> how many (the bestiary)


func start(id: String) -> void:
	if quests.has(id) or not GameData.quests.has(id):
		return
	quests[id] = {"step": 0, "count": 0, "done": false}
	changed.emit()


func active() -> Array[String]:
	var out: Array[String] = []
	for id: String in quests:
		if not bool(quests[id]["done"]):
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool: return bool(GameData.quests[a]["main"]) and not bool(GameData.quests[b]["main"]))
	return out


## Puts a quest at a step without events or rewards (staged scenes, tests). step >= steps: done.
func place(id: String, step: int) -> void:
	var n: int = (GameData.quests[id]["steps"] as Array).size()
	quests[id] = {"step": mini(step, n), "count": 0, "done": step >= n}


func is_done(id: String) -> bool:
	return quests.has(id) and bool(quests[id]["done"])


func step_index(id: String) -> int:
	return int(quests[id]["step"]) if quests.has(id) and not is_done(id) else -1


func step(id: String) -> Dictionary:
	var i: int = step_index(id)
	return GameData.quests[id]["steps"][i] if i >= 0 else {}


func killed(kind: String) -> void:
	kills[kind] = int(kills.get(kind, 0)) + 1


func said_of(npc: String) -> Array:
	return said.get(npc, [])


func mark_said(npc: String, topic: int) -> void:
	if topic < 0:
		return
	if not said.has(npc):
		said[npc] = []
	if not (said[npc] as Array).has(topic):
		(said[npc] as Array).append(topic)


## Has a quest got past step n (or finished)?
func past(id: String, n: int) -> bool:
	return is_done(id) or step_index(id) > n


func set_flag(name: String) -> void:
	if not flags.has(name):
		flags[name] = true
		notify("flag", name)


## Something happened; any quest waiting for exactly this moves on.
func notify(event: String, arg: String = "") -> void:
	for id: String in active():
		var goal: Array = step(id)["goal"]
		if String(goal[0]) != event or String(goal[1]) != arg:
			continue
		quests[id]["count"] = int(quests[id]["count"]) + 1
		if int(quests[id]["count"]) >= (int(goal[2]) if goal.size() > 2 else 1):
			_advance(id)
	changed.emit()


func _advance(id: String) -> void:
	var q: Dictionary = quests[id]
	q["count"] = 0
	q["step"] = int(q["step"]) + 1
	if int(q["step"]) >= (GameData.quests[id]["steps"] as Array).size():
		q["done"] = true
		rewards.append(GameData.quests[id].get("reward", {}))
		quest_done.emit(id)
		if GameData.quests[id].has("next"):
			start(String(GameData.quests[id]["next"]))


func to_dict() -> Dictionary:
	return {"flags": flags, "quests": quests, "said": said, "kills": kills}


func from_dict(d: Dictionary) -> void:
	flags = d.get("flags", {})
	quests = d.get("quests", {})
	said = d.get("said", {})
	kills = d.get("kills", {})
	changed.emit()
