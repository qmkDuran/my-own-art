class_name SpecSlotsView
extends RefCounted
## The specialisation slots as the skill panel shows them: a row of five sockets (a skill's icon when in use, a
## glowing empty socket when open, a lock with its level when not yet), and the card that explains the system the
## first time the skill panel opens (a campaign flag, so it shows once).

const SOCKET: float = 20.0
const GAP: float = 4.0
const ICON: float = 24.0
const FLAG: String = "explained_spec"
const CARD_PAD: float = 12.0
const CARD_W: float = 330.0
const BTN := Vector2(80, 18)
const WRAP: float = CARD_W - CARD_PAD * 2.0
const LINE: float = 13.0


static func socket_rect(origin: Vector2, i: int) -> Rect2:
	return Rect2(origin + Vector2(i * (SOCKET + GAP), 0), Vector2(SOCKET, SOCKET))


static func row_width() -> float:
	return (GameData.player["skill_slot_levels"] as Array).size() * (SOCKET + GAP) - GAP


static func draw_row(ci: CanvasItem, origin: Vector2, p: Progression, skills_tex: Texture2D, t: float) -> void:
	var levels: Array = GameData.player["skill_slot_levels"]
	for i: int in levels.size():
		var r: Rect2 = socket_rect(origin, i)
		if i < p.specialised.size():
			ci.draw_rect(r, TreeArt.FILL_ON)
			var icon: int = int(GameData.skill(String(p.specialised[i]))["icon"])
			ci.draw_texture_rect_region(skills_tex, r.grow(-1.0), Rect2(icon * ICON, 0, ICON, ICON))
			ci.draw_rect(r, UiDraw.FRAME_LIT, false, 1.0)
		elif i < p.spec_slots():
			ci.draw_rect(r, TreeArt.FILL_OFF)
			ci.draw_rect(r, Color(UiDraw.GOLD, 0.6 + 0.4 * sin(t * 3.0)), false, 1.0)
			TreeArt.diamond(ci, r.get_center(), 3.0, Color(UiDraw.GOLD, 0.5))
		else:
			ci.draw_rect(r, Color(0.03, 0.03, 0.05))
			ci.draw_rect(r, UiDraw.LOCKED, false, 1.0)
			UiDraw.text(ci, r.position + Vector2(0, 13), str(int(levels[i])), UiDraw.LOCKED, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


## Tooltip for a socket.
static func socket_tip(p: Progression, i: int) -> Array:
	var levels: Array = GameData.player["skill_slot_levels"]
	if i < p.specialised.size():
		return ["Slot %d: %s" % [i + 1, GameData.skill(String(p.specialised[i]))["name"]], ["Specialised: it levels up and takes tree points.", UiDraw.TEXT]]
	if i < p.spec_slots():
		return ["Slot %d: open" % (i + 1), ["Pick a skill and press Specialise to put it here.", UiDraw.TEXT]]
	return ["Slot %d: locked" % (i + 1), ["Opens at level %d." % int(levels[i]), UiDraw.DIM]]


static func needs_card() -> bool:
	return TutorialTips.active() and not Session.campaign.flags.has(FLAG)


static func dismiss() -> void:
	Session.campaign.set_flag(FLAG)


static func lines() -> Array[String]:
	var lv: PackedStringArray = PackedStringArray((GameData.player["skill_slot_levels"] as Array).map(func(l: Variant) -> String: return str(int(l))))
	return ["You have %d specialisation slots. They open at levels %s." % [lv.size(), ", ".join(lv)],
		"Only a specialised skill gains levels as you use it, and each level is one point for its tree.",
		"Forget frees the slot, but sends that skill back to level 1 with an empty tree.",
		"The sockets at the top right show your slots: lit in use, glowing open, or locked with the level they open at."]


static func card_rect(area: Rect2, ci: CanvasItem) -> Rect2:
	var h: float = CARD_PAD * 2.0 + 22.0 + BTN.y + 8.0
	for l: String in lines():
		h += UiDraw.wrap(ci, l, WRAP).size() * LINE + 4.0
	return Rect2(area.get_center() - Vector2(CARD_W, h) / 2.0, Vector2(CARD_W, h)).abs()


static func button_rect(card: Rect2) -> Rect2:
	return Rect2(card.get_center().x - BTN.x / 2.0, card.end.y - CARD_PAD - BTN.y, BTN.x, BTN.y)


static func draw_card(ci: CanvasItem, area: Rect2) -> void:
	ci.draw_rect(area, Color(0, 0, 0, 0.55))
	var r: Rect2 = card_rect(area, ci)
	UiDraw.box(ci, r, Color(0.07, 0.05, 0.09, 0.98), UiDraw.FRAME_LIT)
	UiDraw.text(ci, r.position + Vector2(0, CARD_PAD + 10.0), "Specialisation", UiDraw.GOLD, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var y: float = r.position.y + CARD_PAD + 30.0
	for l: String in lines():
		for w: String in UiDraw.wrap(ci, l, WRAP):
			UiDraw.text(ci, Vector2(r.position.x + CARD_PAD, y), w, UiDraw.TEXT)
			y += LINE
		y += 4.0
	var b: Rect2 = button_rect(r)
	UiDraw.box(ci, b, Color(0.2, 0.12, 0.05), UiDraw.FRAME_LIT)
	UiDraw.text(ci, b.position + Vector2(0, 12), "Got it", UiDraw.GOLD, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, b.size.x)
