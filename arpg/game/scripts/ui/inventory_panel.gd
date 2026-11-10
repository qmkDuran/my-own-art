class_name InventoryPanel
extends GamePanel
## The armour of God on a paper doll (Eph 6:13-17) and the bag. Click a bag item to equip it; click a worn item to
## take it off. Tooltips show the rolled stats, and for armour of God pieces, the verse.

const CELL: float = 36.0
const COLS: int = 8
const DOLL := Vector2(176, 150)
const SLOT_POS: Dictionary = {
	"helmet": Vector2(176, 50), "amulet": Vector2(256, 50), "sword": Vector2(90, 112), "breastplate": Vector2(176, 112),
	"shield": Vector2(262, 112), "ring": Vector2(100, 174), "belt": Vector2(176, 174), "ring2": Vector2(252, 174),
	"feet": Vector2(176, 236),
}
const BAG_ORIGIN := Vector2(32, 288)

var _icons: Texture2D = preload("res://art/items/icons.png")
var _doll: Texture2D = preload("res://art/michael/idle.png")


func _draw() -> void:
	frame("Armour of God  (I)")
	draw_texture_rect_region(_doll, Rect2(DOLL - Vector2(64, 104), Vector2(128, 128)), Rect2(0, 0, 64, 64), Color(1, 1, 1, 0.3))
	var tip: Variant = []
	var tip_col := Color.WHITE
	for slot: String in SLOT_POS:
		var r := _slot_rect(slot)
		UiDraw.box(self, r, Color(0.1, 0.09, 0.14), UiDraw.FRAME)
		UiDraw.text(self, Vector2(r.position.x - 30, r.end.y + 12), _slot_name(slot), UiDraw.DIM, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 60)
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
				tip = _item_tip(m.inv.bag[i], true)
				tip_col = GameData.rarity_color(m.inv.bag[i]["rarity"])
	var rg: Vector2 = m.stats.damage_range()
	UiDraw.text(self, Vector2(16, size.y - 10), "Life %d   Armour %d   Damage %d-%d   Block %d%%   (C: all stats)" % [
		roundi(m.stats.v("life")), roundi(m.stats.v("armour")), roundi(rg.x), roundi(rg.y), roundi(m.stats.v("block"))], UiDraw.DIM)
	UiDraw.tooltip(self, hover, tip, tip_col)


func _slot_name(slot: String) -> String:
	return String(GameData.items["slots"][slot.trim_suffix("2")]["name"])


func _slot_rect(slot: String) -> Rect2:
	return Rect2(SLOT_POS[slot] - Vector2(17, 17), Vector2(34, 34))


func _cell_rect(i: int) -> Rect2:
	return Rect2(BAG_ORIGIN + Vector2((i % COLS) * CELL, (i / COLS) * CELL), Vector2(CELL - 2, CELL - 2))  # 34: a 32 icon + 1 px


func _item_icon(it: Dictionary, r: Rect2) -> void:
	var c: Vector2i = it["icon"]
	draw_rect(r.grow(-1.0), Color(GameData.rarity_color(it["rarity"]), 0.18))
	draw_texture_rect_region(_icons, Rect2((r.get_center() - Vector2(16, 16)).round(), Vector2(32, 32)), Rect2(c.x * 32, c.y * 32, 32, 32))


## Name, base, every stat, item level; for a bag item, the change against what is worn in that slot (green better,
## red worse); for armour of God pieces, the verse.
func _item_tip(it: Dictionary, compare: bool = false) -> Array:
	var rows: Array = Array(LootGen.describe(it))
	rows.append(["Item level %d" % int(it["ilvl"]), UiDraw.DIM])
	var slot_id: String = m.inv.target_slot(it)
	if compare and m.inv.equipped.has(slot_id):
		var worn: Dictionary = m.inv.equipped[slot_id]
		rows.append(["Compared with %s:" % worn["name"], UiDraw.DIM])
		var keys: Array = it["stats"].keys()
		for k: String in worn["stats"]:
			if not keys.has(k):
				keys.append(k)
		var names: Dictionary = GameData.items["stat_names"]
		for k: String in keys:
			var d: float = float(it["stats"].get(k, 0.0)) - float(worn["stats"].get(k, 0.0))
			if absf(d) < 0.05:
				continue
			var fmt: String = String(names.get(k, k + " %d")).replace("+", "")
			var txt: String = ("+" if d > 0.0 else "-") + (fmt % (absf(d) if "%.1f" in fmt else roundi(absf(d))))
			rows.append([txt, UiDraw.UP if d > 0.0 else UiDraw.DOWN])
	elif compare:
		rows.append(["Nothing worn in this slot", UiDraw.UP])
	var slot: Dictionary = GameData.items["slots"][it["slot"]]
	if slot.get("verse", "") != "":
		rows.append(String(slot["armour_of_god"]) + ":")
		for v: String in UiDraw.verse_lines(slot["verse"], 48):
			rows.append([v, UiDraw.DIM])
	return rows


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
