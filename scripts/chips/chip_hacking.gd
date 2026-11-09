class_name ChipHacking
extends RefCounted
## The rules for hacking a chip's mods with scrap (LinkRod spends it): what each hack costs
## and when it is allowed. The Link Rod screen asks the same questions to grey out buttons.
##
## - Reveal (cheap): a locked mod is hacked open and starts working.
## - Reroll (medium): a revealed mod becomes another mod of the same tier.
## - Upgrade (expensive): a revealed mod goes up one tier, never past the chip's max tier
##   (Chip.max_mod_tier) and never past what the mod table has (overclocked mods stay at 2).

enum Hack { REVEAL, REROLL, UPGRADE }

const COSTS := {Hack.REVEAL: 5, Hack.REROLL: 12, Hack.UPGRADE: 30}
const LABELS := {Hack.REVEAL: "Reveal", Hack.REROLL: "Reroll", Hack.UPGRADE: "Upgrade"}

## Why a hack can't be done ("" when it can).
const NOT_ENOUGH_SCRAP := "Not enough scrap"
const ALREADY_REVEALED := "Already revealed"
const STILL_LOCKED := "Reveal it first"
const AT_MAX_TIER := "At the chip's max tier"
const NO_MOD := "No such mod"


static func cost(hack: Hack) -> int:
	return COSTS[hack]


## "" if `hack` can be done on the chip's mod at `index` with `scrap`, else the reason.
static func refusal(chip: Chip, index: int, hack: Hack, scrap: int) -> String:
	if chip == null or index < 0 or index >= chip.mods.size():
		return NO_MOD
	var rule_refusal := _rule_refusal(chip, chip.mods[index], hack)
	if rule_refusal != "":
		return rule_refusal
	return NOT_ENOUGH_SCRAP if scrap < cost(hack) else ""


static func _rule_refusal(chip: Chip, mod: ChipMod, hack: Hack) -> String:
	match hack:
		Hack.REVEAL:
			return ALREADY_REVEALED if mod.is_revealed else ""
		Hack.REROLL:
			return STILL_LOCKED if not mod.is_revealed else ""
		Hack.UPGRADE:
			if not mod.is_revealed:
				return STILL_LOCKED
			if mod.tier >= chip.max_mod_tier() or not mod.has_next_tier():
				return AT_MAX_TIER
	return ""


## Does the hack (already checked with `refusal`).
static func apply(chip: Chip, index: int, hack: Hack) -> void:
	match hack:
		Hack.REVEAL:
			chip.mods[index].is_revealed = true
		Hack.REROLL:
			ChipRoller.reroll(chip, index)
		Hack.UPGRADE:
			chip.mods[index].tier += 1
