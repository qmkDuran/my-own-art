class_name FilterPanel
extends GamePanel
## The loot filter: show or hide each rarity, hide plain (normal and magic) pieces of chosen slots, emphasise
## rares and better. Hidden drops never land.

const BTN := Vector2(120, 20)
const GAP: float = 6.0


func _rarity_rect(i: int) -> Rect2:
	return Rect2(14.0, CONTENT_Y + 26.0 + i * (BTN.y + GAP), BTN.x, BTN.y)


func _slot_rect(i: int) -> Rect2:
	return Rect2(size.x - 14.0 - BTN.x, CONTENT_Y + 26.0 + i * (BTN.y + 4.0), BTN.x, BTN.y - 2.0)


func _emph_rect() -> Rect2:
	return Rect2(14.0, size.y - 34.0, BTN.x * 2.0, BTN.y)


func _content() -> void:
	UiDraw.text(self, Vector2(14, CONTENT_Y + 16.0), "Show rarity", UiDraw.DIM, UiDraw.SMALL)
	UiDraw.text(self, Vector2(size.x - 14.0 - BTN.x, CONTENT_Y + 16.0), "Hide plain pieces", UiDraw.DIM, UiDraw.SMALL)
	for i: int in LootFilter.RARITIES.size():
		var r: String = LootFilter.RARITIES[i]
		var on: bool = bool(LootFilter.show_rarity[r])
		button(_rarity_rect(i), "%s: %s" % [GameData.items["rarity_names"][r], "shown" if on else "hidden"], on)
	for i: int in LootFilter.SLOTS.size():
		var s: String = LootFilter.SLOTS[i]
		var hid: bool = LootFilter.hide_plain_slots.has(s)
		button(_slot_rect(i), "%s %s" % ["hide" if hid else "show", s], not hid)
	button(_emph_rect(), "Emphasise rare+: %s" % ("on" if LootFilter.emphasise else "off"), LootFilter.emphasise)
	UiDraw.text(self, Vector2(14, size.y - 44.0), "Hidden so far: %d" % LootFilter.hidden_count, UiDraw.DIM, UiDraw.SMALL)


func _click(at: Vector2, _button: int) -> void:
	for i: int in LootFilter.RARITIES.size():
		if _rarity_rect(i).has_point(at):
			LootFilter.toggle_rarity(LootFilter.RARITIES[i])
	for i: int in LootFilter.SLOTS.size():
		if _slot_rect(i).has_point(at):
			LootFilter.toggle_slot(LootFilter.SLOTS[i])
	if _emph_rect().has_point(at):
		LootFilter.emphasise = not LootFilter.emphasise
	Audio.sfx("ui_click", -8.0)
	g.mark_dirty()
