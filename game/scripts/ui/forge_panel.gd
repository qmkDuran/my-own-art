class_name ForgePanel
extends GamePanel
## Fenn's Ember Forge. Put an item on the anvil (click it in your bag or on your body while the forge is open),
## choose an affix if the craft needs one, then Kindle, Temper, Quench or Anneal. Each craft spends a material and
## some of the item's Heat; when Heat runs out the item is finished. Your materials are listed below.

const ROW: float = 13.0
const X: float = 14.0
const BTN_H: float = 22.0
const CRAFTS: Array[String] = ["kindle", "temper", "quench", "anneal"]
const MATS: Array[String] = ["ash", "kindle", "temper", "quench", "anneal"]
const LIST_Y: float = 70.0

var item: Dictionary = {}
var affix: int = -1
var _last: String = ""


func put(it: Dictionary) -> void:
	item = it
	affix = -1
	_last = ""
	Audio.sfx("ui_click", -6.0)


func affix_rect(i: int) -> Rect2:
	return Rect2(X, CONTENT_Y + LIST_Y + i * (ROW + 3.0) - 10.0, size.x - X * 2.0, ROW + 2.0)


func craft_rect(i: int) -> Rect2:
	var w: float = (size.x - X * 2.0 - 8.0) / 2.0
	return Rect2(X + (i % 2) * (w + 8.0), size.y - 100.0 + (i / 2) * (BTN_H + 6.0), w, BTN_H)


func lockers_rect() -> Rect2:
	return Rect2(size.x - X - 80.0, CONTENT_Y + 6.0, 80.0, BTN_H - 4.0)


func _content() -> void:
	var y: float = CONTENT_Y + 18.0
	if item.is_empty():
		UiDraw.text(self, Vector2(X, y), "Click an item in your bag to put it on the anvil.", UiDraw.DIM)
	else:
		UiDraw.text(self, Vector2(X, y), String(item["name"]), GameData.rarity_color(item["rarity"]))
		UiDraw.text(self, Vector2(X, y + ROW), "Heat %d" % int(item.get("heat", 0)), Pal.c("flame"))
		_affixes()
	for i: int in CRAFTS.size():
		_craft_button(i)
	button(lockers_rect(), "Lockers")
	if _last != "":
		UiDraw.text(self, Vector2(X, size.y - 108.0), _last, UiDraw.GOLD, UiDraw.SMALL)
	_wallet()


func _affixes() -> void:
	for i: int in (item["affixes"] as Array).size():
		var a: Dictionary = item["affixes"][i]
		var r: Rect2 = affix_rect(i)
		if i == affix:
			draw_rect(r, Color(UiDraw.FRAME_LIT, 0.2))
			draw_rect(r, UiDraw.FRAME_LIT, false, 1.0)
		UiDraw.text(self, r.position + Vector2(4, 11), "%s   T%d" % [GameData.stat_line(String(a["stat"]), float(a["value"])), int(a["tier"])],
			ItemText.AFFIX)


func _craft_button(i: int) -> void:
	var c: String = CRAFTS[i]
	var hr: Vector2i = Forge.heat_range(item, c, affix) if not item.is_empty() else Vector2i.ZERO
	var label: String = "%s x%d  heat %d-%d" % [GameData.crafting["materials"][c]["name"].split(" ")[0], g.player.inv.material(c), hr.x, hr.y]
	button(craft_rect(i), label, Forge.block(item, c, affix, g.player.inv.materials) == "")


## Materials in hand, two short lines (names without "Ember").
func _wallet() -> void:
	var parts: PackedStringArray = []
	for m: String in MATS:
		parts.append("%s %d" % [String(GameData.crafting["materials"][m]["name"]).split(" ")[0], g.player.inv.material(m)])
	UiDraw.text(self, Vector2(0, size.y - 22.0), "   ".join(parts.slice(0, 3)), UiDraw.DIM, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	UiDraw.text(self, Vector2(0, size.y - 10.0), "   ".join(parts.slice(3)), UiDraw.DIM, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, size.x)


func _click(at: Vector2, _button: int) -> void:
	if lockers_rect().has_point(at):
		g.ui.open(g.ui.stash)
		return
	if not item.is_empty():
		for i: int in (item["affixes"] as Array).size():
			if affix_rect(i).has_point(at):
				affix = i
				Audio.sfx("ui_click", -8.0)
				return
	for i: int in CRAFTS.size():
		if craft_rect(i).has_point(at):
			_do(CRAFTS[i])


func _do(c: String) -> void:
	var spent: int = Forge.craft(item, c, affix, g.player.inv.materials)
	if spent == 0:
		Audio.sfx("hiss", -12.0)
		return
	affix = mini(affix, (item["affixes"] as Array).size() - 1)
	_last = "%s: %d Heat spent" % [GameData.crafting["materials"][c]["name"], spent]
	Audio.sfx("slam", -10.0, 1.6)
	Fx.flash(g.fx_layer, g.player.global_position, 80.0, Pal.c("flame"), 1.0, 0.2)
	g.player.inv.changed.emit()


func _hover(at: Vector2) -> void:
	for i: int in CRAFTS.size():
		if craft_rect(i).has_point(at):
			var c: String = CRAFTS[i]
			var rows: Array = [String(GameData.crafting["materials"][c]["name"]), [String(GameData.crafting["materials"][c]["text"]), UiDraw.TEXT]]
			var why: String = Forge.block(item, c, affix, g.player.inv.materials)
			if why != "":
				rows.append([why, UiDraw.DOWN])
			tip(rows)
			return
	if not item.is_empty() and Rect2(X, CONTENT_Y + 6.0, size.x, 16.0).has_point(at):
		tip(ItemText.rows(item, {}, g.player.prog.level), GameData.rarity_color(item["rarity"]))
