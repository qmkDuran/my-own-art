class_name Restoration
extends RefCounted
## The healing world: which heal stage the Vale has reached, from befriended species and story flags
## (data/restoration.json). Stages heal in order; each map says which regions each stage heals.


static func stage_for(befriended: int, flags: Dictionary) -> int:
	var stage: int = 0
	for s: Dictionary in Db.restoration["stages"]:
		if not _met(s, befriended, flags):
			break
		stage = int(s["stage"])
	return stage


static func _met(s: Dictionary, befriended: int, flags: Dictionary) -> bool:
	if s.has("befriended") and befriended < int(s["befriended"]):
		return false
	if s.has("flag") and not flags.get(String(s["flag"]), false):
		return false
	return true


static func message(stage: int) -> String:
	for s: Dictionary in Db.restoration["stages"]:
		if int(s["stage"]) == stage:
			return String(s["message"])
	return ""


static func is_healed(region_stage: int, world_stage: int) -> bool:
	return region_stage <= world_stage
