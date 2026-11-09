class_name ShardReward
extends RefCounted
## The permanent upgrade a Glimmer Shard gives (see DESIGN.md, "Glimmer Shards"): each shard
## in a level picks one with its `reward` export, and ShardInventory remembers which one
## every found shard gave, so the upgrade comes back with the save.
##
## Where each upgrade lands:
## - CHIP_SLOT: LinkRod counts them for its slots (see LinkRod.slot_count).
## - SKILL_POINT: given once on pickup as a Progression bonus point (saved by Progression).
## - MAX_HEAT, AID_CHARGE: Heat and TrainerAid add their count when Emberoo spawns, and
##   `apply_live` adds one straight away when a shard is picked up mid-level.

enum Kind { CHIP_SLOT, SKILL_POINT, MAX_HEAT, AID_CHARGE }

## What the toast says after "GLIMMER SHARD: ".
const TOAST_TEXT := {
	Kind.CHIP_SLOT: "+1 chip slot",
	Kind.SKILL_POINT: "+1 skill point",
	Kind.MAX_HEAT: "+1 max Heat",
	Kind.AID_CHARGE: "+1 Trainer's Aid charge",
}
const TOAST_PREFIX := "GLIMMER SHARD: "
## How a reward is written in the save (by name, so reordering the enum never breaks one).
const SAVE_NAMES := {
	Kind.CHIP_SLOT: "chip_slot", Kind.SKILL_POINT: "skill_point",
	Kind.MAX_HEAT: "max_heat", Kind.AID_CHARGE: "aid_charge",
}


static func toast_text(kind: Kind) -> String:
	return TOAST_PREFIX + TOAST_TEXT[kind]


## The reward a save name stands for, or -1 for an unknown name.
static func from_save_name(save_name: String) -> int:
	for kind: Kind in SAVE_NAMES:
		if SAVE_NAMES[kind] == save_name:
			return kind
	return -1


## Gives the reward's one-off part, once, when the shard is first found.
static func grant_once(kind: Kind) -> void:
	if kind == Kind.SKILL_POINT:
		Progression.add_skill_points(1)


## Adds a just-found shard's upgrade to the living player (one that spawns later reads
## ShardInventory itself, in Heat and TrainerAid).
static func apply_live(player: Node, kind: Kind) -> void:
	if player == null:
		return
	match kind:
		Kind.MAX_HEAT:
			var heat := player.get_node_or_null(Heat.NODE_NAME) as Heat
			if heat != null:
				heat.max_heat += 1
				heat.heat_changed.emit(heat.heat, heat.max_heat)
		Kind.AID_CHARGE:
			var aid := player.get_node_or_null(TrainerAid.NODE_NAME) as TrainerAid
			if aid != null:
				aid.max_charges += 1
				aid.add_charge()
