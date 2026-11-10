class_name InventoryPanel
extends GamePanel
## The armour of God on a paper doll (Eph 6:13-17) and the bag. Click a bag item to equip it; click a worn item to
## take it off. Tooltips show the rolled stats, and for armour of God pieces, the verse.

const CELL: float = 28.0
const COLS: int = 8
const DOLL := Vector2(176, 132)
const SLOT_POS: Dictionary = {
	"helmet": Vector2(176, 44), "amulet": Vector2(232, 62), "breastplate": Vector2(176, 100), "sword": Vector2(96, 112),
	"shield": Vector2(256, 112), "belt": Vector2(176, 156), "ring": Vector2(112, 172), "ring2": Vector2(240, 172),
	"feet": Vector2(176, 210),
}
const BAG_ORIGIN := Vector2(64, 248)

var _icons: Texture2D = preload("res://art/items/icons.png")
var _doll: Texture2D = preload("res://art/michael/idle.png")


func _draw() -> void:
	frame("Armour of God  (I)")
	draw_texture_rect_region(_doll, Rect2(DOLL - Vector2(64, 96), Vector2(128, 128)), Rect2(0, 0, 64, 64), Color(1, 1, 1, 0.35))
	var tip := PackedStringArray()
	var tip_col := Color.WHITE
	for slot: String in SLOT_POS:
		var r := _slot_rect(slot)
		UiDraw.box(self, r, Color(0.1, 0.09, 0.14), UiDraw.FRAME)
		if m.inv.equipped.has(slot):
			var it: Dictionary = m.inv.equipped[slot]
			_item_icon(it, r)
			if r.has_point(hover):
				tip = _item_tip(it)
				tip_col = GameData.rarity_color(it["rarity"])
		elif r.has_point(hover):
			tip = _slot_tip(slot)
	for i: int in Inventory.CELLS:
		var r := _cell_rect(i)
		UiDraw.box(self, r, Color(0.09, 0.08, 0.12), Color(0.3, 0.27, 0.22))
		if i < m.inv.bag.size():
			_item_icon(m.inv.bag[i], r)
			if r.has_point(hover):
				tip = _item_tip(m.inv.bag[i])
				tip_col = GameData.rarity_color(m.inv.bag[i]["rarity"])
	UiDraw.text(self, Vector2(16, size.y - 10), "Life %d   Armour %d   Damage %d   Block %d%%" % [
		roundi(m.stats.v("life")), roundi(m.stats.v("armour")), roundi(m.stats.v("damage")), roundi(m.stats.v("block"))], UiDraw.DIM)
	UiDraw.tooltip(self, hover, tip, tip_col)


func _slot_rect(slot: String) -> Rect2:
	return Rect2(SLOT_POS[slot] - Vector2(17, 17), Vector2(34, 34))


func _cell_rect(i: int) -> Rect2:
	return Rect2(BAG_ORIGIN + Vector2((i % COLS) * CELL, (i / COLS) * CELL), Vector2(CELL - 2, CELL - 2))


func _item_icon(it: Dictionary, r: Rect2) -> void:
	var c: Vector2i = it["icon"]
	draw_rect(r.grow(-1.0), Color(GameData.rarity_color(it["rarity"]), 0.18))
	draw_texture_rect_region(_icons, Rect2(r.get_center() - Vector2(16, 16), Vector2(32, 32)) if r.size.x > 30.0 \
		else Rect2(r.position, r.size), Rect2(c.x * 32, c.y * 32, 32, 32))


func _item_tip(it: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = LootGen.describe(it)
	lines.append("Item level %d" % int(it["ilvl"]))
	var slot: Dictionary = GameData.items["slots"][it["slot"]]
	if slot.get("verse", "") != "":
		lines.append("")
		lines.append(String(slot["armour_of_god"]) + ":")
		lines.append_array(UiDraw.verse_lines(slot["verse"], 48))
	return lines


func _slot_tip(slot: String) -> PackedStringArray:
	var base: Dictionary = GameData.items["slots"][slot.trim_suffix("2")]
	var lines := PackedStringArray([String(base["name"]) + " (empty)"])
	if base.get("verse", "") != "":
		lines.append_array(UiDraw.verse_lines(base["verse"], 48))
	return lines


func clicked(at: Vector2) -> void:
	for slot: String in SLOT_POS:
		if _slot_rect(slot).has_point(at):
			m.inv.unequip(slot)
			return
	for i: int in m.inv.bag.size():
		if _cell_rect(i).has_point(at):
			m.inv.equip(i)
			Audio.sfx("pickup", -12.0, 0.8)
			return
