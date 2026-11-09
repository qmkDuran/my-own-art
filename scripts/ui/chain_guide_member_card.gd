class_name ChainGuideMemberCard
extends PanelContainer
## One creature's card in the chain guide, edged in its element colour:
##   header   its sprite, name, element and swap key
##   skills   one row per skill: key, icon, name, the status it sets up (icon), cooldown,
##            then what it does in one line with real numbers
##   signal   its Signal Skill: what it does, then one row per trigger:
##            [status icon] Rooted  ->  Drown (the reaction, in its colour)
##   outro    what it leaves behind when you swap it out
## Built once from a ChainGuideMember.

const PORTRAIT_CROP := Vector2i(16, 16)
const PORTRAIT_SCALE := 2
const COLUMN_GAP := 5
const HEADER_GAP := 8
const BLOCK_GAP := 2
const SIGNAL_BLOCK_GAP := 3
const SKILL_ICON_SCALE := 2
const SIGNAL_TITLE := "Signal Skill"
const SIGNAL_HINT := "Swap in (key %s) when an enemy near you is:"
const RECRUIT_SIGNAL_HINT := "Swap in when an enemy near you is:"
const OUTRO_TITLE := "On swap out"
const SETS_UP := "sets"
const COOLDOWN_FORMAT := "%ss"
const NO_SIGNAL_NOTE := "No Signal Skill yet: its set-ups feed the others."

var _member: ChainGuideMember
var _element_color: Color


func _init(member: ChainGuideMember, width: float) -> void:
	_member = member
	_element_color = ElementColors.for_element(member.element)
	add_theme_stylebox_override("panel", ChainGuideWidgets.card_style(_element_color))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = width
	var column := ChainGuideWidgets.make_column(COLUMN_GAP)
	add_child(column)
	column.add_child(_header())
	column.add_child(ChainGuideWidgets.make_divider(_element_color))
	for row in member.skills:
		column.add_child(_skill_block(row))
	column.add_child(ChainGuideWidgets.make_divider(_element_color))
	column.add_child(_signal_block())
	if not member.outro_line.is_empty():
		column.add_child(ChainGuideWidgets.make_divider(_element_color))
		column.add_child(_outro_block())


func _header() -> HBoxContainer:
	var header := ChainGuideWidgets.make_row(HEADER_GAP)
	if _member.icon != null:
		header.add_child(ChainGuideIcon.texture(_member.icon, PORTRAIT_SCALE, PORTRAIT_CROP))
	header.add_child(ChainGuideWidgets.make_label(_member.display_name, _element_color, ChainGuideWidgets.LARGE_SIZE))
	header.add_child(ChainGuideWidgets.make_spacer())
	header.add_child(ChainGuideWidgets.make_label(_member.element.to_upper(), _element_color))
	if not _member.swap_key.is_empty():
		header.add_child(ChainGuideWidgets.make_key_cap(_member.swap_key))
	return header


func _skill_block(row: ChainGuideMember.SkillRow) -> VBoxContainer:
	var block := ChainGuideWidgets.make_column(BLOCK_GAP)
	var title_row := ChainGuideWidgets.make_row()
	title_row.add_child(ChainGuideWidgets.make_key_cap(row.keys))
	if row.icon != null:
		title_row.add_child(ChainGuideIcon.texture(row.icon, SKILL_ICON_SCALE))
	var title_color := ApolloPalette.GREY if row.is_locked else ApolloPalette.CREAM
	title_row.add_child(ChainGuideWidgets.make_label(row.title, title_color))
	title_row.add_child(ChainGuideWidgets.make_spacer())
	_add_sets_up(title_row, row.set_up_status)
	if row.cooldown > 0.0:
		title_row.add_child(ChainGuideWidgets.make_label(COOLDOWN_FORMAT % ChainGuideWidgets.short_number(row.cooldown), ApolloPalette.GREY))
	block.add_child(title_row)
	block.add_child(ChainGuideWidgets.make_wrapped(row.text, ApolloPalette.GREY_LIGHT))
	return block


func _signal_block() -> VBoxContainer:
	var block := ChainGuideWidgets.make_column(SIGNAL_BLOCK_GAP)
	if not _member.has_signal_skill():
		block.add_child(ChainGuideWidgets.make_section_title(SIGNAL_TITLE, ApolloPalette.GREY))
		block.add_child(ChainGuideWidgets.make_wrapped(NO_SIGNAL_NOTE, ApolloPalette.GREY))
		return block
	var title_row := ChainGuideWidgets.make_row()
	title_row.add_child(ChainGuideWidgets.make_section_title(SIGNAL_TITLE, ApolloPalette.GOLD))
	title_row.add_child(ChainGuideWidgets.make_label(_member.signal_name, _element_color))
	block.add_child(title_row)
	block.add_child(ChainGuideWidgets.make_wrapped(_member.signal_line, ApolloPalette.GREY_LIGHT))
	var hint := RECRUIT_SIGNAL_HINT if _member.swap_key.is_empty() else SIGNAL_HINT % _member.swap_key
	block.add_child(ChainGuideWidgets.make_label(hint, ApolloPalette.CREAM))
	for trigger in _member.triggers:
		block.add_child(_trigger_row(trigger))
	return block


## [icon] Rooted  ->  Drown   (the Signal Skill's name when there's no reaction); statuses
## with the same result share the row: [icon] Broken [icon] Soaked  ->  Ambush
func _trigger_row(trigger: ChainGuideMember.Trigger) -> HBoxContainer:
	var row := ChainGuideWidgets.make_row()
	for status_name in trigger.statuses:
		row.add_child(ChainGuideWidgets.make_status_chip(status_name))
	row.add_child(ChainGuideIcon.arrow(ApolloPalette.CREAM))
	if trigger.reaction == null:
		row.add_child(ChainGuideWidgets.make_label(_member.signal_name, _element_color))
	else:
		row.add_child(ChainGuideWidgets.make_label(trigger.reaction.display_name, trigger.reaction.color))
	return row


func _outro_block() -> VBoxContainer:
	var block := ChainGuideWidgets.make_column(BLOCK_GAP)
	var title_row := ChainGuideWidgets.make_row()
	title_row.add_child(ChainGuideWidgets.make_section_title(OUTRO_TITLE, ApolloPalette.GOLD))
	title_row.add_child(ChainGuideWidgets.make_spacer())
	_add_sets_up(title_row, _member.outro_status)
	block.add_child(title_row)
	block.add_child(ChainGuideWidgets.make_wrapped(_member.outro_line, ApolloPalette.GREY_LIGHT))
	return block


## "sets [icon]" at the end of a title row, for a move that puts `status_name` on enemies.
func _add_sets_up(title_row: HBoxContainer, status_name: String) -> void:
	if status_name.is_empty():
		return
	title_row.add_child(ChainGuideWidgets.make_label(SETS_UP, ApolloPalette.GREY))
	title_row.add_child(ChainGuideIcon.status(status_name))
