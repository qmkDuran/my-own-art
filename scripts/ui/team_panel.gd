class_name TeamPanel
extends Control
## Project B's team on the HUD (bottom left): one card per Party member with its sprite,
## its key (1/2/3), a health bar and its element's colour. The creature on the field sits
## raised in a gold frame with its name above; while the swap cooldown runs, the benched
## cards are veiled; a defeated member is greyed out with a red cross; a member whose Signal
## Skill is armed (the condition it needs is on an enemy right now) glows in its element
## colour, its key number flashes, and a badge above it shows the icon of that condition
## (e.g. the roots of Rooted on Ripfin's card): press its key. No words: the chain guide
## (Tab) explains every icon.
## Finds the Party by its group, so levels without one simply show nothing.

const CARD_SIZE := Vector2(20, 20)
const CARD_GAP := 4
const ICON_TOP_LEFT := Vector2(2, 2)
const ICON_SIZE := Vector2(16, 16)
const HEALTH_BAR_TOP := 22
const HEALTH_BAR_HEIGHT := 2
## How far the active card rises above the others, in pixels.
const ACTIVE_RISE := 2
const NAME_GAP := 7
const KEY_TOP_LEFT := Vector2(1, 14)
## Health shares below which the bar turns gold, then red.
const WOUNDED_SHARE := 0.5
const CRITICAL_SHARE := 0.25
## How fast the "Signal armed" outline pulses, in radians per second.
const ARMED_PULSE_SPEED := 10.0
## The condition badge over a lit card: how far above the card its bottom sits, its padding
## around the 7×7 icon, and how far it bobs.
const BADGE_BOTTOM_GAP := 9
const BADGE_PADDING := 1
const BADGE_BOB := 1.0

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
		_draw_icon(member.team_icon, top_left + ICON_TOP_LEFT, tint)
	if not is_active and not is_defeated and _party.swap_cooldown_fraction() > 0.0:
		var veil_height := CARD_SIZE.y * _party.swap_cooldown_fraction()
		draw_rect(Rect2(top_left, Vector2(CARD_SIZE.x, veil_height)), Color(ApolloPalette.NIGHT, 0.65))
	if is_defeated:
		draw_line(top_left + Vector2(3, 3), top_left + CARD_SIZE - Vector2(3, 3), ApolloPalette.RED_LIGHT, 1.0)
		draw_line(top_left + Vector2(CARD_SIZE.x - 3, 3), top_left + Vector2(3, CARD_SIZE.y - 3), ApolloPalette.RED_LIGHT, 1.0)
	var frame_color := ApolloPalette.GOLD if is_active else ApolloPalette.STONE_LIGHT
	draw_rect(card, frame_color, false, 1.0)
	var armed_status := _party.armed_status(slot_index)
	var is_armed := not armed_status.is_empty()
	if is_armed:
		_draw_armed_glow(card, element_color)
		_draw_condition_badge(top_left, armed_status, element_color)
	else:
		draw_rect(card.grow(1), ApolloPalette.OUTLINE, false, 1.0)
	_draw_key(slot_index, top_left, is_active, is_armed)
	_draw_health_bar(top_left + Vector2(0, HEALTH_BAR_TOP), member_health)


## The member's icon; a creature drawn bigger than 16×16 shows its middle 16×16.
func _draw_icon(icon: Texture2D, at: Vector2, tint: Color) -> void:
	var crop := Vector2(maxf(0.0, icon.get_width() - ICON_SIZE.x), maxf(0.0, icon.get_height() - ICON_SIZE.y))
	var region := Rect2((crop / 2.0).floor(), Vector2(minf(icon.get_width(), ICON_SIZE.x), minf(icon.get_height(), ICON_SIZE.y)))
	draw_texture_rect_region(icon, Rect2(at, region.size), region, tint)


## A pulsing outline in the member's element colour: its Intro is armed, swap it in now.
func _draw_armed_glow(card: Rect2, element_color: Color) -> void:
	var pulse := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 1000.0 * ARMED_PULSE_SPEED)
	draw_rect(card.grow(1), Color(element_color, pulse), false, 1.0)
	draw_rect(card.grow(2), Color(element_color, pulse), false, 1.0)
	draw_rect(card.grow(3), Color(ApolloPalette.WHITE, pulse * 0.6), false, 1.0)


## A small framed badge above the card, in the element colour, holding the icon of the
## status that armed it, with a stem down to the card. It bobs so the eye catches it.
func _draw_condition_badge(card_top_left: Vector2, status_name: String, element_color: Color) -> void:
	var side := ChainStatusIcons.SIZE + 2 + BADGE_PADDING * 2
	var bob := roundf(BADGE_BOB * sin(Time.get_ticks_msec() / 1000.0 * ARMED_PULSE_SPEED * 0.5))
	var centre_x := roundf(card_top_left.x + CARD_SIZE.x / 2.0)
	var badge := Rect2(Vector2(centre_x - floorf(side / 2.0), card_top_left.y - BADGE_BOTTOM_GAP - side + bob), Vector2(side, side))
	draw_line(Vector2(centre_x, badge.end.y), Vector2(centre_x, card_top_left.y - 1), element_color, 1.0)
	draw_rect(badge.grow(1), ApolloPalette.OUTLINE)
	draw_rect(badge, element_color)
	draw_rect(badge.grow(-1), ApolloPalette.DARK)
	ChainStatusIcons.draw(self, status_name, badge.position + Vector2.ONE * (BADGE_PADDING + 1))


## The card's key number (1/2/3): gold on the field, cream on the bench, and flashing
## white and gold on a dark tab while the card is lit, so the key to press stands out.
func _draw_key(slot_index: int, top_left: Vector2, is_active: bool, is_armed: bool) -> void:
	var key := str(slot_index + 1)
	var key_color := ApolloPalette.GOLD if is_active else ApolloPalette.CREAM
	if is_armed:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * ARMED_PULSE_SPEED)
		key_color = ApolloPalette.GOLD.lerp(ApolloPalette.WHITE, pulse)
		var tab := Rect2(top_left + KEY_TOP_LEFT - Vector2.ONE, Vector2(PixelFont.width_of(key) + 2, PixelFont.GLYPH_HEIGHT + 2))
		draw_rect(tab.grow(1), ApolloPalette.OUTLINE)
		draw_rect(tab, ApolloPalette.DARK)
	PixelFont.draw_text(self, key, top_left + KEY_TOP_LEFT, key_color, ApolloPalette.OUTLINE)


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
