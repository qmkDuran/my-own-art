class_name TeamPanel
extends Control
## Project B's team on the HUD (bottom left): one card per Party member with its sprite,
## its key (1/2/3), a health bar and its element's colour. The creature on the field sits
## raised in a gold frame with its name above; while the swap cooldown runs, the benched
## cards are veiled; a defeated member is greyed out with a red cross; a member whose Intro
## is armed (a set-up is waiting for it) glows in its element colour.
## Finds the Party by its group, so levels without one simply show nothing.

const CARD_SIZE := Vector2(20, 20)
const CARD_GAP := 4
const ICON_TOP_LEFT := Vector2(2, 2)
const HEALTH_BAR_TOP := 22
const HEALTH_BAR_HEIGHT := 2
## How far the active card rises above the others, in pixels.
const ACTIVE_RISE := 2
const NAME_GAP := 7
const KEY_TOP_LEFT := Vector2(1, 14)
## Health shares below which the bar turns gold, then red.
const WOUNDED_SHARE := 0.5
const CRITICAL_SHARE := 0.25
## How fast the "Intro armed" outline pulses, in radians per second.
const ARMED_PULSE_SPEED := 10.0

var _party: Party


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if not is_instance_valid(_party):
		_party = get_tree().get_first_node_in_group(Party.GROUP) as Party
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(_party) or _party.members.is_empty():
		return
	for slot_index in _party.members.size():
		_draw_card(slot_index, _card_top_left(slot_index))
	var active := _party.active_member()
	var name_left := _card_top_left(_party.active_slot) + Vector2(0, -NAME_GAP)
	PixelFont.draw_text(self, active.display_name.to_upper(), name_left, ApolloPalette.CREAM, ApolloPalette.OUTLINE)


func _card_top_left(slot_index: int) -> Vector2:
	var rise := ACTIVE_RISE if slot_index == _party.active_slot else 0
	return Vector2(slot_index * (CARD_SIZE.x + CARD_GAP), -rise)


func _draw_card(slot_index: int, top_left: Vector2) -> void:
	var member := _party.members[slot_index]
	var member_health := member.health_component()
	var is_active := slot_index == _party.active_slot
	var is_defeated := member_health.is_dead()
	var element_color := ElementColors.for_element(member.element)
	var card := Rect2(top_left, CARD_SIZE)
	draw_rect(card, ApolloPalette.DARK)
	draw_rect(card.grow(-1), Color(element_color, 0.25))
	if member.team_icon != null:
		var tint := ApolloPalette.GREY if is_defeated else Color.WHITE
		draw_texture(member.team_icon, top_left + ICON_TOP_LEFT, tint)
	if not is_active and not is_defeated and _party.swap_cooldown_fraction() > 0.0:
		var veil_height := CARD_SIZE.y * _party.swap_cooldown_fraction()
		draw_rect(Rect2(top_left, Vector2(CARD_SIZE.x, veil_height)), Color(ApolloPalette.NIGHT, 0.65))
	if is_defeated:
		draw_line(top_left + Vector2(3, 3), top_left + CARD_SIZE - Vector2(3, 3), ApolloPalette.RED_LIGHT, 1.0)
		draw_line(top_left + Vector2(CARD_SIZE.x - 3, 3), top_left + Vector2(3, CARD_SIZE.y - 3), ApolloPalette.RED_LIGHT, 1.0)
	var frame_color := ApolloPalette.GOLD if is_active else ApolloPalette.STONE_LIGHT
	draw_rect(card, frame_color, false, 1.0)
	if _party.is_intro_armed(slot_index):
		_draw_armed_glow(card, element_color)
	else:
		draw_rect(card.grow(1), ApolloPalette.OUTLINE, false, 1.0)
	var key_color := ApolloPalette.GOLD if is_active else ApolloPalette.CREAM
	PixelFont.draw_text(self, str(slot_index + 1), top_left + KEY_TOP_LEFT, key_color, ApolloPalette.OUTLINE)
	_draw_health_bar(top_left + Vector2(0, HEALTH_BAR_TOP), member_health)


## A pulsing outline in the member's element colour: its Intro is armed, swap it in now.
func _draw_armed_glow(card: Rect2, element_color: Color) -> void:
	var pulse := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 1000.0 * ARMED_PULSE_SPEED)
	draw_rect(card.grow(1), Color(element_color, pulse), false, 1.0)
	draw_rect(card.grow(2), Color(element_color, pulse), false, 1.0)
	draw_rect(card.grow(3), Color(ApolloPalette.WHITE, pulse * 0.6), false, 1.0)


func _draw_health_bar(top_left: Vector2, member_health: Health) -> void:
	var share := clampf(float(member_health.current_health) / float(member_health.max_health), 0.0, 1.0)
	draw_rect(Rect2(top_left - Vector2.ONE, Vector2(CARD_SIZE.x + 2, HEALTH_BAR_HEIGHT + 2)), ApolloPalette.OUTLINE)
	draw_rect(Rect2(top_left, Vector2(CARD_SIZE.x, HEALTH_BAR_HEIGHT)), ApolloPalette.COAL)
	if share > 0.0:
		draw_rect(Rect2(top_left, Vector2(roundf(CARD_SIZE.x * share), HEALTH_BAR_HEIGHT)), _health_color(share))


func _health_color(share: float) -> Color:
	if share <= CRITICAL_SHARE:
		return ApolloPalette.RED_LIGHT
	if share <= WOUNDED_SHARE:
		return ApolloPalette.GOLD
	return ApolloPalette.GREEN_LIGHT
