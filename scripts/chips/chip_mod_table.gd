class_name ChipModTable
extends RefCounted
## Every modifier a hacked chip can carry, in one place (see DESIGN.md, "Loot: hacked chips").
##
## To add a mod: add an entry here, then wire its effect in ChipEffects (stat mods) or give
## it an overclock component (see ChipEffects.OVERCLOCK_NODES), and its before → after row
## in ChipStatSheet. Each entry:
##   "text":   what it does, "{amount}" filled with the tier's number
##   "tiers":  tier -> amount (a tier missing here can't be rolled or upgraded to)
##   "weight": how often it rolls compared to the others
##   "overclocked": true for the rare effect mods (tier 2 only, see OVERCLOCK_CHANCE)

## Mod tiers run 1..TOP_TIER. A chip from act N rolls tier-N mods (sometimes N + 1) and can
## be upgraded up to N + 1 (see Chip.max_mod_tier), so Act 1 chips hold tier 1-2 mods.
const TOP_TIER := 3
## Chance that a tier-2 roll is one of the rare overclocked mods instead of a stat mod.
const OVERCLOCK_CHANCE := 0.12
const OVERCLOCK_TIER := 2

const JAB_DAMAGE := "jab_damage"
const MAX_HEALTH := "max_health"
const MAX_HEAT := "max_heat"
const UPPERCUT_COOLDOWN := "uppercut_cooldown"
const CRIT_CHANCE := "crit_chance"
const BURN_SECONDS := "burn_seconds"
const AID_HEAL := "aid_heal"
const POISON_RESIST := "poison_resist"
const RUN_SPEED := "run_speed"
const DODGE_COOLDOWN := "dodge_cooldown"
const JAB_PIERCE := "jab_pierce"
const DODGE_TRAIL := "dodge_trail"
const UPPERCUT_PULL := "uppercut_pull"

const MODS := {
	JAB_DAMAGE: {"text": "+{amount} jab damage", "tiers": {1: 1, 2: 2, 3: 3}, "weight": 10},
	MAX_HEALTH: {"text": "+{amount} max health", "tiers": {1: 2, 2: 3, 3: 5}, "weight": 10},
	MAX_HEAT: {"text": "+{amount} max Heat", "tiers": {1: 1, 2: 2, 3: 3}, "weight": 8},
	UPPERCUT_COOLDOWN: {"text": "-{amount}s Flame Uppercut cooldown", "tiers": {1: 0.3, 2: 0.5, 3: 0.8}, "weight": 8},
	CRIT_CHANCE: {"text": "+{amount}% crit chance", "tiers": {1: 3, 2: 5, 3: 8}, "weight": 8},
	BURN_SECONDS: {"text": "Burn lasts +{amount}s", "tiers": {1: 0.5, 2: 1, 3: 1.5}, "weight": 7},
	AID_HEAL: {"text": "+{amount} Aid heal", "tiers": {1: 1, 2: 2, 3: 3}, "weight": 7},
	POISON_RESIST: {"text": "Poison resistance: {amount}% shorter poison", "tiers": {1: 25, 2: 50, 3: 75}, "weight": 6},
	RUN_SPEED: {"text": "+{amount} run speed", "tiers": {1: 4, 2: 6, 3: 10}, "weight": 7},
	DODGE_COOLDOWN: {"text": "-{amount}s dodge cooldown", "tiers": {1: 0.05, 2: 0.1, 3: 0.15}, "weight": 6},
	JAB_PIERCE: {"text": "Jabs hit a second enemy behind the first", "tiers": {2: 1}, "weight": 1, "overclocked": true},
	DODGE_TRAIL: {"text": "Dodge leaves a short fire trail", "tiers": {2: 1}, "weight": 1, "overclocked": true},
	UPPERCUT_PULL: {"text": "Flame Uppercut pulls enemies in", "tiers": {2: 1}, "weight": 1, "overclocked": true},
}


static func has_mod(mod_id: String) -> bool:
	return MODS.has(mod_id)


static func is_overclocked(mod_id: String) -> bool:
	return MODS[mod_id].get("overclocked", false)


static func has_tier(mod_id: String, tier: int) -> bool:
	return MODS.has(mod_id) and MODS[mod_id]["tiers"].has(tier)


## The mod's number at `tier` (e.g. 2 for "+2 max health").
static func amount(mod_id: String, tier: int) -> float:
	return float(MODS[mod_id]["tiers"][tier])


## What the mod does at `tier`, e.g. "+2 max health" or "-0.5s Flame Uppercut cooldown".
static func text(mod_id: String, tier: int) -> String:
	return String(MODS[mod_id]["text"]).format({"amount": number_text(amount(mod_id, tier))})


## Mods that can roll at `tier`: overclocked ones or stat ones, never both in one list.
static func ids_for(tier: int, overclocked: bool) -> Array[String]:
	var ids: Array[String] = []
	for mod_id: String in MODS:
		if is_overclocked(mod_id) == overclocked and has_tier(mod_id, tier):
			ids.append(mod_id)
	return ids


static func weight(mod_id: String) -> int:
	return MODS[mod_id]["weight"]


## 2 -> "2", 0.5 -> "0.5", 0.05 -> "0.05".
static func number_text(number: float) -> String:
	if is_equal_approx(number, roundf(number)):
		return str(roundi(number))
	return str(snappedf(number, 0.01))
