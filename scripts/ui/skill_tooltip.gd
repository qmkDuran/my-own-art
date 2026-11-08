class_name SkillTooltip
extends Control
## A small card above a skill slot while the mouse hovers it: the skill's name, its Heat cost
## and cooldown, and what it does. Same see-through dark card as the speech bubbles.

const FONT_SIZE := 6
## Width the description wraps at, in game pixels.
const TEXT_WIDTH := 96.0
## Gap between the card and the slot, and the screen edge.
const MARGIN := 3.0

var _card: PanelContainer
var _name: Label
var _numbers: Label
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
	_numbers.text = "Heat %s  ·  %ss cooldown" % [_property(skill, "heat_cost", 0), _property(skill, "cooldown", 0)]
	_description.text = str(_property(skill, "description", ""))
	_description.visible = not _description.text.is_empty()
	_card.reset_size()
	_card.visible = true
	_card.global_position = _card_position(slot_rect)


func hide_tooltip() -> void:
	_card.visible = false


## Centred above the slot, kept inside the screen.
func _card_position(slot_rect: Rect2) -> Vector2:
	var screen := get_viewport_rect().size
	var x := slot_rect.get_center().x - _card.size.x / 2.0
	var y := slot_rect.position.y - _card.size.y - MARGIN
	return Vector2(
		roundf(clampf(x, MARGIN, screen.x - _card.size.x - MARGIN)),
		roundf(maxf(MARGIN, y)))


func _build_card() -> void:
	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(ApolloPalette.OUTLINE, 0.85)
	style.border_color = ApolloPalette.STONE
	style.set_border_width_all(1)
	style.set_content_margin_all(3)
	_card.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	_name = UiLabel.make(FONT_SIZE, ApolloPalette.GOLD)
	_numbers = UiLabel.make(FONT_SIZE, ApolloPalette.GREY)
	_description = UiLabel.make(FONT_SIZE, ApolloPalette.CREAM)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size.x = TEXT_WIDTH
	column.add_child(_name)
	column.add_child(_numbers)
	column.add_child(_description)
	_card.add_child(column)
	add_child(_card)


static func _property(skill: Resource, property: String, fallback: Variant) -> Variant:
	var value: Variant = skill.get(property)
	return fallback if value == null else value
