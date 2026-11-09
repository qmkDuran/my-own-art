class_name LinkRodText
extends RefCounted
## The Link Rod screen's words: short chip summaries and the rich-text lines for a mod
## (what it does, its tier, and its exact before → after numbers from ChipStatSheet).

const LOCKED_NOTE := "locked: reveal it to make it work"
const OVERCLOCKED := "OVERCLOCKED"
const NO_PLAYER_NUMBERS := "(numbers show once Emberoo is in the zone)"


## "WR-007  ∙  2 mods, 1 locked".
static func chip_summary(chip: Chip) -> String:
	var text := "%s  ∙  %d mod%s" % [chip.display_name(), chip.mods.size(), "" if chip.mods.size() == 1 else "s"]
	if chip.locked_count() > 0:
		text += ", %d locked" % chip.locked_count()
	return text


## "[T1] +2 max health" (an overclocked mod in its own colour), or "[T?] ???".
static func mod_title_bbcode(mod: ChipMod) -> String:
	if not mod.is_revealed:
		return EmberTreeFactText.colored("[T?]  %s" % ChipMod.LOCKED_TEXT, LinkRodPalette.LOCKED)
	var tier := EmberTreeFactText.colored("[T%d]  " % mod.tier, LinkRodPalette.CHIP)
	if mod.is_overclocked():
		return tier + EmberTreeFactText.colored(OVERCLOCKED + "  ", LinkRodPalette.OVERCLOCK) + EmberTreeFactText.escape(mod.text())
	return tier + EmberTreeFactText.escape(mod.text())


## The mod's numbers on Emberoo, e.g. "Max Health 10 → 12": for a chip in the rod, without
## it → now (gold); otherwise now → with it (green). Empty for locked and overclocked mods.
static func mod_change_bbcode(sheet: ChipStatSheet, mod: ChipMod, is_equipped: bool) -> String:
	if not mod.is_revealed or not ChipStatSheet.is_stat_mod(mod.mod_id):
		return ""
	if not sheet.has_player():
		return EmberTreeFactText.colored(NO_PLAYER_NUMBERS, EmberTreePalette.GREY)
	var color := EmberTreePalette.GOLD if is_equipped else EmberTreePalette.BETTER
	return stat_change_bbcode(sheet.change_text(mod.mod_id, mod.amount(), is_equipped), ChipStatSheet.label(mod.mod_id), color)


## What an upgrade would do, e.g. "Upgrade to T2: Max Health 12 → 13" (counted with the
## chip in the rod), or "Upgrade to T2: +3 max health" when there are no live numbers.
static func upgrade_bbcode(sheet: ChipStatSheet, mod: ChipMod, is_equipped: bool) -> String:
	var next := ChipMod.new(mod.mod_id, mod.tier + 1, true)
	var line := "Upgrade to T%d: %s" % [next.tier, next.text()]
	if sheet.has_player() and ChipStatSheet.is_stat_mod(mod.mod_id):
		line = "Upgrade to T%d" % next.tier
		var now := sheet.value_with(mod.mod_id, 0.0 if is_equipped else mod.amount())
		var after := sheet.value_with(mod.mod_id, next.amount() - (mod.amount() if is_equipped else 0.0))
		line += ": %s %s → %s" % [ChipStatSheet.label(mod.mod_id), ChipStatSheet.number_text(mod.mod_id, now), ChipStatSheet.number_text(mod.mod_id, after)]
	return EmberTreeFactText.colored(line, EmberTreePalette.GREY)


## "Max Health 10 → 12" with "→ 12" in `color`.
static func stat_change_bbcode(change: String, stat_label: String, color: Color) -> String:
	var arrow_at := change.find(ChipStatSheet.ARROW)
	return EmberTreeFactText.escape("%s %s" % [stat_label, change.substr(0, arrow_at)]) + EmberTreeFactText.colored(change.substr(arrow_at), color)
