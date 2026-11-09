class_name ChipEffects
extends Node
## Applies the mods of the chips in the Link Rod's slots to Emberoo (like EmberTreeEffects
## for the tree). Only revealed mods work; a locked "???" mod does nothing yet.
##
## Lives in the level (GameLayer), so the creature scene stays untouched. It re-applies
## whenever the rod changes (equip, unequip, hack, load) and remembers what it has already
## added, so the totals are always exact and never counted twice. Stat mods go through
## ChipStatSheet (the numbers the Link Rod screen shows); overclocked mods add a small
## component to the player while they are equipped.

## Overclocked mod -> the component script that does it, added to the player under the mod's id.
const OVERCLOCK_NODES := {
	ChipModTable.JAB_PIERCE: preload("res://scripts/chips/overclocks/jab_pierce.gd"),
	ChipModTable.DODGE_TRAIL: preload("res://scripts/chips/overclocks/dodge_fire_trail.gd"),
	ChipModTable.UPPERCUT_PULL: preload("res://scripts/chips/overclocks/uppercut_pull.gd"),
}

## The player the amounts below were added to; a new player (a reloaded zone) starts at zero.
var _player: Node = null
## Mod id -> the amount added to the player so far (after floors, see ChipStatSheet).
var _applied: Dictionary[String, float] = {}
## Mod id -> the equipped total it was worked out from.
var _wanted: Dictionary[String, float] = {}


func _ready() -> void:
	# Wait one frame so the player has been added to the level (same as EmberTreeEffects).
	await get_tree().process_frame
	LinkRod.changed.connect(apply_equipped)
	apply_equipped()


## What the equipped chips' revealed mods add up to: mod id -> total amount.
static func equipped_totals() -> Dictionary[String, float]:
	var totals: Dictionary[String, float] = {}
	for chip in LinkRod.equipped_chips():
		for mod in chip.mods:
			if mod.is_revealed:
				totals[mod.mod_id] = totals.get(mod.mod_id, 0.0) + mod.amount()
	return totals


func apply_equipped() -> void:
	var player := PlayerFinder.find(self)
	if player == null:
		return
	if player != _player:
		_adopt(player)
	var totals := equipped_totals()
	var sheet := ChipStatSheet.new(player)
	for mod_id: String in ChipStatSheet.STATS:
		_apply_stat(sheet, mod_id, totals.get(mod_id, 0.0))
	for mod_id: String in OVERCLOCK_NODES:
		_set_overclock(mod_id, totals.has(mod_id))


func _apply_stat(sheet: ChipStatSheet, mod_id: String, wanted: float) -> void:
	if is_equal_approx(wanted, _wanted.get(mod_id, 0.0)):
		return
	var applied: float = _applied.get(mod_id, 0.0)
	var landed := sheet.landed_amount(mod_id, applied, wanted)
	sheet.change_stat(mod_id, landed - applied)
	_applied[mod_id] = landed
	_wanted[mod_id] = wanted


## A new player starts with nothing from chips. Its Flame Uppercut gets its own copy of the
## skill data, so a cooldown chip never changes the shared resource file.
func _adopt(player: Node) -> void:
	_player = player
	_applied.clear()
	_wanted.clear()
	var uppercut := player.get_node_or_null(FlameUppercut.NODE_PATH) as SkillAction
	if uppercut != null and uppercut.skill != null:
		uppercut.skill = uppercut.skill.duplicate()


func _set_overclock(mod_id: String, is_wanted: bool) -> void:
	var existing := _player.get_node_or_null(mod_id)
	if is_wanted and existing == null:
		var overclock: Node = OVERCLOCK_NODES[mod_id].new()
		overclock.name = mod_id
		_player.add_child(overclock)
	elif not is_wanted and existing != null:
		existing.name = mod_id + "_removed"  # frees its name now, in case it comes straight back
		existing.queue_free()
