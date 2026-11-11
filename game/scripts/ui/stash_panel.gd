class_name StashPanel
extends GamePanel
## Fenn's lockers: storage shared across every visit. Click an item here to take it into your bag; with the stash
## open, click a bag item (inventory panel) to put it away.

const CELL: float = 30.0
const COLS: int = 8
const ICON: float = 24.0

var _icons: Texture2D


func _ready() -> void:
	_icons = PropSprite.tex("res://art/ui/items.png")


func cell_rect(i: int) -> Rect2:
	var o := Vector2(roundf((size.x - COLS * CELL) / 2.0), CONTENT_Y + 10.0)
	return Rect2(o + Vector2(i % COLS, i / COLS) * CELL, Vector2(CELL, CELL))


func _content() -> void:
	for i: int in Session.stash.size():
		var r: Rect2 = cell_rect(i)
		draw_rect(r.grow(-1.0), Color(0.05, 0.045, 0.07))
		draw_rect(r.grow(-1.0), Color(UiDraw.FRAME, 0.35), false, 1.0)
		var it: Dictionary = Session.stash[i]
		if not it.is_empty():
			draw_rect(r.grow(-2.0), Color(GameData.rarity_color(it["rarity"]), 0.15))
			draw_texture_rect_region(_icons, Rect2((r.get_center() - Vector2(ICON, ICON) * 0.5).round(), Vector2(ICON, ICON)),
				Rect2(int(it["icon"][1]) * ICON, int(it["icon"][0]) * ICON, ICON, ICON))
	UiDraw.text(self, Vector2(0, size.y - 10.0), "Click to take. With this open, click a bag item to store it.", UiDraw.DIM,
		UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, size.x)


## Puts a bag item into the first free locker. Returns true if it fit.
func store(it: Dictionary) -> bool:
	var i: int = Session.stash.find({})
	if i < 0:
		return false
	Session.stash[i] = it
	return true


func _click(at: Vector2, _button: int) -> void:
	for i: int in Session.stash.size():
		var it: Dictionary = Session.stash[i]
		if cell_rect(i).has_point(at) and not it.is_empty() and g.player.inv.add(it):
			Session.stash[i] = {}
			Audio.sfx("pickup", -8.0)
			g.mark_dirty()


func _hover(at: Vector2) -> void:
	for i: int in Session.stash.size():
		var it: Dictionary = Session.stash[i]
		if cell_rect(i).has_point(at) and not it.is_empty():
			tip(ItemText.rows(it, {}, g.player.prog.level), GameData.rarity_color(it["rarity"]))
