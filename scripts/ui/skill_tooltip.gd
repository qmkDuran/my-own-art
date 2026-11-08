class_name SkillTooltip
extends Control
## A small card above a skill slot while the mouse hovers it: the skill's name, its Heat cost
## and cooldown, and what it does. A HudCard: the Ember Tree's card style and Monogram font,
## laid out at twice the game's resolution (sizes below are in card pixels) and shown at half size.

const FONT_SIZE := EmberTreeFonts.TEXT_SIZE
## Width the description wraps at, in card pixels (96 game pixels).
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


## Shows the card for a skill (any Resource with display_name, heat_cost, cooldown, description),
## just above the slot's rectangle (in screen coordinates).
func show_for(skill: Resource, slot_rect: Rect2) -> void:
	if skill == null:
		hide_tooltip()
		return
	_name.text = str(_property(skill, "display_name", "Skill"))
	var cooldown := String.num(float(_property(skill, "cooldown", 0.0)))
	_numbers.text = "HEAT %s  ∙  %sS COOLDOWN" % [_property(skill, "heat_cost", 0), cooldown]
	_description.text = str(_property(skill, "description", ""))
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


static func _property(skill: Resource, property: String, fallback: Variant) -> Variant:
	var value: Variant = skill.get(property)
	return fallback if value == null else value
