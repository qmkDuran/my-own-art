class_name SkillTooltip
extends Control
## A small card above a skill slot while the mouse hovers it: the skill's name, its Heat cost
## and cooldown, and what it does. A HudCard: the Ember Tree's card style and Monogram font,
## laid out in UI pixels (sizes below are in card pixels) and shown scaled to the game (HudCard).
## What it does is the Ember Tree's own facts text (EmberTreeSkillFacts), so the two never
## disagree: its last line (the cost, e.g. "Costs 3 Heat ∙ 2s cooldown") goes in orange
## under the name, the rest below the divider. It is the HUD's last child, so it draws over
## every other card (a discovery toast, a banner) while the mouse is on a slot.

const FONT_SIZE := EmberTreeFonts.TEXT_SIZE
## Width the description wraps at, in card pixels (128 game pixels at 1080p).
const TEXT_WIDTH := 192.0
## Gap between the lines, in card pixels.
const LINE_GAP := 2
## Gap between the card and the slot, and the screen edge, in game pixels.
const MARGIN := 3.0

var _card: PanelContainer
var _name: Label
var _numbers: Label
var _divider: ColorRect
var _description: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_card()
	hide_tooltip()


## Shows the card for a skill (any Resource with display_name, heat_cost, cooldown) and its
## Ember Tree facts, just above the slot's rectangle (in screen coordinates). Without facts
## the card shows just the name, Heat cost and cooldown.
func show_for(skill: Resource, facts: String, slot_rect: Rect2) -> void:
	if skill == null:
		hide_tooltip()
		return
	_name.text = str(_property(skill, "display_name", "Skill"))
	var lines := facts.strip_edges().split("\n")
	if lines.size() > 1:
		_numbers.text = lines[lines.size() - 1]
		_description.text = "\n".join(lines.slice(0, lines.size() - 1))
	else:
		_numbers.text = _cost_line(skill)
		_description.text = facts.strip_edges()
	_description.visible = not _description.text.is_empty()
	_divider.visible = _description.visible
	_card.reset_size()
	_card.visible = true
	_card.global_position = _card_position(slot_rect)


func hide_tooltip() -> void:
	_card.visible = false


## Centred above the slot, kept inside the screen, on whole game pixels.
func _card_position(slot_rect: Rect2) -> Vector2:
	var screen := get_viewport_rect().size
	var card_size := HudCard.size_on_screen(_card)
	var x := slot_rect.get_center().x - card_size.x / 2.0
	var y := slot_rect.position.y - card_size.y - MARGIN
	return Vector2(
		roundf(clampf(x, MARGIN, screen.x - card_size.x - MARGIN)),
		roundf(maxf(MARGIN, y)))


## Name (gold), numbers (orange capitals, like the Ember Tree's tags), a warm line, then
## what the skill does (cream).
func _build_card() -> void:
	_card = HudCard.make()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", LINE_GAP)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name = UiLabel.make(FONT_SIZE, EmberTreePalette.GOLD)
	_numbers = UiLabel.make(FONT_SIZE, EmberTreePalette.ORANGE)
	_divider = EmberTreeWidgets.make_divider(TEXT_WIDTH)
	_description = UiLabel.make(FONT_SIZE, EmberTreePalette.CREAM)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size.x = TEXT_WIDTH
	for part: Control in [_name, _numbers, _divider, _description]:
		column.add_child(part)
	_card.add_child(column)
	add_child(_card)


static func _cost_line(skill: Resource) -> String:
	var cooldown := String.num(float(_property(skill, "cooldown", 0.0)))
	return "Costs %s Heat  ∙  %ss cooldown" % [_property(skill, "heat_cost", 0), cooldown]


static func _property(skill: Resource, property: String, fallback: Variant) -> Variant:
	var value: Variant = skill.get(property)
	return fallback if value == null else value
