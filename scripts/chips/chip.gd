class_name Chip
extends RefCounted
## A hacked control chip, taken from a Warden: 1-3 modifiers (ChipMod) that work on
## Emberoo while the chip sits in a Link Rod slot. Its tier is the act it dropped in, and
## its mods can be upgraded one tier above that (Act 1 chips: tier 1-2 mods).
## Plain data; LinkRod owns the chips and changes them.

## A chip's serial is shown as e.g. "WR-007" (a Warden rod's chip number).
const NAME_FORMAT := "WR-%03d"
const MAX_MODS := 3
## Scrap a salvaged chip gives: SALVAGE_BASE + SALVAGE_PER_TIER for every tier of its mods.
const SALVAGE_BASE := 3
const SALVAGE_PER_TIER := 2

## Unique per save, so equipped chips can be saved by serial.
var serial: int
var tier: int
var mods: Array[ChipMod] = []


func _init(chip_serial: int = 0, chip_tier: int = 1) -> void:
	serial = chip_serial
	tier = chip_tier


func display_name() -> String:
	return NAME_FORMAT % serial


## The highest tier its mods can be upgraded to.
func max_mod_tier() -> int:
	return mini(tier + 1, ChipModTable.TOP_TIER)


func locked_count() -> int:
	return mods.filter(func(mod: ChipMod) -> bool: return not mod.is_revealed).size()


func has_overclock() -> bool:
	return mods.any(func(mod: ChipMod) -> bool: return mod.is_revealed and mod.is_overclocked())


func has_mod(mod_id: String) -> bool:
	return mods.any(func(mod: ChipMod) -> bool: return mod.mod_id == mod_id)


func salvage_value() -> int:
	var tiers := 0
	for mod in mods:
		tiers += mod.tier
	return SALVAGE_BASE + SALVAGE_PER_TIER * tiers


func to_save_data() -> Dictionary:
	return {"serial": serial, "tier": tier, "mods": mods.map(func(mod: ChipMod) -> Dictionary: return mod.to_save_data())}


## A chip from a save, or null if it is damaged (no serial or no readable mod).
static func from_save_data(data: Dictionary) -> Chip:
	var chip := Chip.new(
		SaveData.read_int(data, "serial", 0, 0, SaveData.NO_LIMIT),
		SaveData.read_int(data, "tier", 1, 1, ChipModTable.TOP_TIER))
	var saved_mods: Variant = data.get("mods")
	if saved_mods is Array:
		for mod_data: Variant in saved_mods:
			var mod := ChipMod.from_save_data(mod_data) if mod_data is Dictionary else null
			if mod != null and chip.mods.size() < MAX_MODS:
				chip.mods.append(mod)
	return chip if chip.serial > 0 and not chip.mods.is_empty() else null
