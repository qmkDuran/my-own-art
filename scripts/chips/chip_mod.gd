class_name ChipMod
extends RefCounted
## One modifier on a hacked chip: which mod (an id from ChipModTable), its tier, and
## whether it has been hacked open yet. A locked mod shows as "???" and does nothing until
## revealed (see LinkRod.reveal).

const LOCKED_TEXT := "???"

var mod_id: String
var tier: int
var is_revealed: bool


func _init(id: String = "", mod_tier: int = 1, revealed: bool = false) -> void:
	mod_id = id
	tier = mod_tier
	is_revealed = revealed


func amount() -> float:
	return ChipModTable.amount(mod_id, tier)


func is_overclocked() -> bool:
	return ChipModTable.is_overclocked(mod_id)


## What it does, e.g. "+2 max health", or "???" while locked.
func text() -> String:
	return ChipModTable.text(mod_id, tier) if is_revealed else LOCKED_TEXT


## Whether the table has a next tier for it at all (overclocked mods have only tier 2).
func has_next_tier() -> bool:
	return ChipModTable.has_tier(mod_id, tier + 1)


func to_save_data() -> Dictionary:
	return {"id": mod_id, "tier": tier, "revealed": is_revealed}


## A mod from a save, or null if it names a mod or tier the table doesn't have.
static func from_save_data(data: Dictionary) -> ChipMod:
	var id: Variant = data.get("id")
	var mod_tier := SaveData.read_int(data, "tier", 1, 1, ChipModTable.TOP_TIER)
	if not id is String or not ChipModTable.has_tier(id, mod_tier):
		return null
	return ChipMod.new(id, mod_tier, data.get("revealed", false) == true)
