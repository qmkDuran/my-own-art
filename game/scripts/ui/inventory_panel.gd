class_name InventoryPanel
extends GamePanel
## Equipment (a paper doll of ten slots) and the bag. Click a bag item to wear it (it swaps with what was worn),
## click a worn item to take it off. Hover for the item's numbers and the difference against what you wear.

const CELL: float = 30.0
const EQ: float = 34.0
const ICON: float = 24.0
const DOLL: Dictionary = {"head": Vector2(1, 0), "staff": Vector2(0, 1), "body": Vector2(1, 1), "relic": Vector2(2, 1),
	"hands": Vector2(0, 2), "belt": Vector2(1, 2), "feet": Vector2(2, 2), "ring1": Vector2(0, 3), "neck": Vector2(1, 3),
	"ring2": Vector2(2, 3)}
const DOLL_STEP := Vector2(44, 40)
const DOLL_Y: float = 34.0
const BAG_Y: float = 214.0

var _icons: Texture2D


func _ready() -> void:
	_icons = PropSprite.tex("res://art/ui/items.png")


func _doll_origin() -> Vector2:
	return Vector2(roundf((size.x - (DOLL_STEP.x * 2.0 + EQ)) / 2.0), DOLL_Y)


func eq_rect(slot: String) -> Rect2:
	return Rect2(_doll_origin() + DOLL[slot] * DOLL_STEP, Vector2(EQ, EQ))


func bag_origin() -> Vector2:
	return Vector2(roundf((size.x - Inventory.BAG_COLS * CELL) / 2.0), BAG_Y)


func bag_rect(i: int) -> Rect2:
	return Rect2(bag_origin() + Vector2(i % Inventory.BAG_COLS, i / Inventory.BAG_COLS) * CELL, Vector2(CELL, CELL))


func _content() -> void:
	var inv: Inventory = g.player.inv
	for slot: String in DOLL:
		var r: Rect2 = eq_rect(slot)
		UiDraw.box(self, r, Color(0.05, 0.04, 0.07))
		var it: Dictionary = inv.equipped[slot]
		if it.is_empty():
			UiDraw.text(self, r.position + Vector2(0, 20), String(GameData.items["slot_names"][slot]), UiDraw.LOCKED,
				UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		else:
			_item(r, it)
	UiDraw.text(self, Vector2(0, BAG_Y - 8.0), "Bag", UiDraw.DIM, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	for i: int in inv.bag.size():
		var r: Rect2 = bag_rect(i)
		draw_rect(r.grow(-1.0), Color(0.05, 0.045, 0.07))
		draw_rect(r.grow(-1.0), Color(UiDraw.FRAME, 0.35), false, 1.0)
		if not (inv.bag[i] as Dictionary).is_empty():
			_item(r, inv.bag[i])
	var st: Stats = g.player.stats
	UiDraw.text(self, Vector2(0, size.y - 10.0), "Life %d   Armour %d   Light radius %+d%%" % [roundi(st.max_life()), roundi(st.armour()),
		roundi(st.v("light_radius_pct"))], UiDraw.DIM, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, size.x)


func _item(r: Rect2, it: Dictionary) -> void:
	var col: Color = GameData.rarity_color(it["rarity"])
	draw_rect(r.grow(-2.0), Color(col, 0.12))
	draw_rect(r.grow(-2.0), Color(col, 0.6), false, 1.0)
	var src := Rect2(int(it["icon"][1]) * ICON, int(it["icon"][0]) * ICON, ICON, ICON)
	draw_texture_rect_region(_icons, Rect2((r.get_center() - Vector2(ICON, ICON) * 0.5).round(), Vector2(ICON, ICON)), src)
	if int(it.get("req", 1)) > g.player.prog.level:
		draw_rect(r.grow(-2.0), Color(0.6, 0.1, 0.1, 0.35))
	if bool(it.get("new", false)):                          # just picked up, not looked at yet
		UiDraw.text(self, r.position + Vector2(2, 9), "NEW", UiDraw.GOLD, UiDraw.SMALL)


func _click(at: Vector2, _button: int) -> void:
	var inv: Inventory = g.player.inv
	if g.ui.forge.visible:
		_to_anvil(at)
		return
	for slot: String in DOLL:
		if eq_rect(slot).has_point(at) and inv.unequip(slot):
			Audio.sfx("pickup", -8.0)
			return
	for i: int in inv.bag.size():
		if bag_rect(i).has_point(at) and not (inv.bag[i] as Dictionary).is_empty():
			if g.ui.stash.visible:
				if g.ui.stash.store(inv.bag[i]):
					inv.remove_at(i)
				return
			if inv.equip(i, g.player.prog.level):
				Audio.sfx("pickup", -6.0, 0.9)
			else:
				g.hud.notice("Requires level %d" % int(inv.bag[i].get("req", 1)))
			return


## With the forge open, a click puts the item (in the bag or worn) on the anvil instead.
func _to_anvil(at: Vector2) -> void:
	var inv: Inventory = g.player.inv
	for slot: String in DOLL:
		if eq_rect(slot).has_point(at) and not (inv.equipped[slot] as Dictionary).is_empty():
			g.ui.forge.put(inv.equipped[slot])
	for i: int in inv.bag.size():
		if bag_rect(i).has_point(at) and not (inv.bag[i] as Dictionary).is_empty():
			g.ui.forge.put(inv.bag[i])


func _hover(at: Vector2) -> void:
	var inv: Inventory = g.player.inv
	for slot: String in DOLL:
		if eq_rect(slot).has_point(at) and not (inv.equipped[slot] as Dictionary).is_empty():
			var it: Dictionary = inv.equipped[slot]
			tip(ItemText.rows(it, {}, g.player.prog.level), GameData.rarity_color(it["rarity"]))
			return
	for i: int in inv.bag.size():
		if bag_rect(i).has_point(at) and not (inv.bag[i] as Dictionary).is_empty():
			var it: Dictionary = inv.bag[i]
			it.erase("new")                                     # seen
			var worn: Dictionary = inv.equipped[inv.target_slot(it)]
			var rows: Array = ItemText.rows(it, worn, g.player.prog.level) + ItemText.effect_rows(g.player, it)
			if worn.is_empty():
				tip(rows, GameData.rarity_color(it["rarity"]))
			else:
				g.ui.tooltip.show_pair(rows, ItemText.rows(worn, {}, g.player.prog.level), get_global_mouse_position(),
					GameData.rarity_color(it["rarity"]), GameData.rarity_color(worn["rarity"]))
			return
