class_name DebugChipGrant
extends RefCounted
## DEBUG ONLY (DebugControls' F7): a random tier-2 hacked chip and some scrap, to try the
## Link Rod and its hacking without hunting Wardens.

const CHIP_TIER := 2
const SCRAP := 50
## Debug chips always carry three mods, each a tier up half the time.
const QUALITY := {"mod_count_weights": [0, 0, 1], "high_roll_chance": 0.5}


static func grant() -> void:
	LinkRod.add_scrap(SCRAP)
	LinkRod.add_chip(LinkRod.roll_chip(CHIP_TIER, QUALITY))
