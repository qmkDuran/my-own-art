class_name ChipRoller
extends RefCounted
## Rolls new chips and new mods (drops, rerolls) from ChipModTable.
##
## A drop's "quality" says how many mods it gets and how lucky its tiers are:
##   "mod_count_weights": weights for 1, 2 and 3 mods
##   "high_roll_chance":  chance each mod rolls one tier above the chip's tier
## Mods start locked; a rerolled mod comes back revealed (you just hacked it).

## A Warden's chip: mostly 1-2 mods.
const WARDEN_QUALITY := {"mod_count_weights": [4, 4, 2], "high_roll_chance": 0.2}
## The Warden Captain's chip: 2-3 mods, often a tier up.
const CAPTAIN_QUALITY := {"mod_count_weights": [0, 3, 7], "high_roll_chance": 0.5}

## Seeded by a test driver for repeatable rolls; random otherwise.
static var rng := RandomNumberGenerator.new()


static func _static_init() -> void:
	rng.randomize()


static func roll_chip(serial: int, tier: int, quality: Dictionary) -> Chip:
	var chip := Chip.new(serial, clampi(tier, 1, ChipModTable.TOP_TIER))
	var mod_count := _pick_weighted_index(quality["mod_count_weights"]) + 1
	for index in mod_count:
		var is_high_roll := rng.randf() < float(quality["high_roll_chance"])
		var mod_tier := mini(chip.tier + (1 if is_high_roll else 0), chip.max_mod_tier())
		chip.mods.append(roll_mod(mod_tier, _ids_on(chip)))
	return chip


## A new locked mod at `tier`, not one of `taken_ids`. A tier-2 roll is sometimes overclocked.
static func roll_mod(tier: int, taken_ids: Array[String]) -> ChipMod:
	var wants_overclock := tier == ChipModTable.OVERCLOCK_TIER and rng.randf() < ChipModTable.OVERCLOCK_CHANCE
	var choices := _free_ids(tier, wants_overclock, taken_ids)
	if choices.is_empty():
		choices = _free_ids(tier, not wants_overclock, taken_ids)
	return ChipMod.new(_pick_weighted_id(choices), tier)


## Swaps the chip's mod at `index` for a different one of the same tier, revealed.
static func reroll(chip: Chip, index: int) -> void:
	var taken := _ids_on(chip)
	var new_mod := roll_mod(chip.mods[index].tier, taken)
	new_mod.is_revealed = true
	chip.mods[index] = new_mod


static func _ids_on(chip: Chip) -> Array[String]:
	var ids: Array[String] = []
	for mod in chip.mods:
		ids.append(mod.mod_id)
	return ids


static func _free_ids(tier: int, overclocked: bool, taken_ids: Array[String]) -> Array[String]:
	var free_ids: Array[String] = []
	free_ids.assign(ChipModTable.ids_for(tier, overclocked).filter(func(id: String) -> bool: return not taken_ids.has(id)))
	return free_ids


static func _pick_weighted_id(ids: Array[String]) -> String:
	var weights: Array[int] = []
	for id in ids:
		weights.append(ChipModTable.weight(id))
	return ids[_pick_weighted_index(weights)]


static func _pick_weighted_index(weights: Array) -> int:
	var total := 0
	for weight: int in weights:
		total += weight
	var roll := rng.randi_range(1, total)
	for index in weights.size():
		roll -= int(weights[index])
		if roll <= 0:
			return index
	return weights.size() - 1
