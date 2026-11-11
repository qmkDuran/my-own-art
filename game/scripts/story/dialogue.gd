class_name Dialogue
extends RefCounted
## Picks what a person says now (data/dialogue.json) from the campaign's state, and applies what the talk does.

static func pick(npc: String, c: Campaign, said: Array) -> Dictionary:
	var d: Dictionary = GameData.dialogue[npc]
	for i: int in (d["topics"] as Array).size():
		var t: Dictionary = d["topics"][i]
		if bool(t.get("once", false)) and said.has(i):
			continue
		if holds(t.get("when", {}), c):
			var out: Dictionary = t.duplicate()
			out["index"] = i
			return out
	return {"lines": [d["idle"]], "index": -1, "do": {"service": d.get("service", "")}}


static func holds(w: Dictionary, c: Campaign) -> bool:
	if w.has("quest_step") and c.step_index(String(w["quest_step"][0])) != int(w["quest_step"][1]):
		return false
	if w.has("quest_past") and not c.past(String(w["quest_past"][0]), int(w["quest_past"][1])):
		return false
	if w.has("quest_active") and c.step_index(String(w["quest_active"])) < 0:
		return false
	if w.has("quest_done") and not c.is_done(String(w["quest_done"])):
		return false
	if w.has("flag") and not c.flags.has(String(w["flag"])):
		return false
	if w.has("not_flag") and c.flags.has(String(w["not_flag"])):
		return false
	if w.has("clock_after") and not _clock_after(int(w["clock_after"])):
		return false
	return true


## Loop-aware talk: true once the Tuesday clock (in a looping zone) is past `minutes` after three.
static func _clock_after(minutes: int) -> bool:
	var g: Game = Game.current
	return g != null and g.loop != null and g.loop.minute() >= minutes


## After the last line: start quests, set flags; returns the service to open ("" if none).
static func apply(topic: Dictionary, c: Campaign) -> String:
	var act: Dictionary = topic.get("do", {})
	if act.has("start_quest"):
		c.start(String(act["start_quest"]))
	if act.has("flag"):
		c.set_flag(String(act["flag"]))
	return String(act.get("service", ""))
