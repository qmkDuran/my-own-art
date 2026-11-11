class_name PassivePanel
extends GamePanel
## Passive trees: the Lamplighter tree and the three masteries (tabs). Nodes sit in rows by the points needed in
## that tree; click to add a point, right-click to refund. A mastery is chosen once at its level; the other two
## open after 20 points in the Lamplighter tree.

const TAB := Vector2(146, 22)
const NODE := Vector2(110, 36)
const STEP := Vector2(120, 54)
const GRID_Y: float = 92.0
const GLYPH: float = 16.0
const TREES: Array[String] = ["lamplighter", "beacon", "mothwright", "duskwalker"]
const ROWS: int = 5
const KEYSTONE_WRAP: float = 260.0

var tab: String = "lamplighter"
var _glyphs: Texture2D


func _ready() -> void:
	_glyphs = PropSprite.tex("res://art/ui/glyphs.png")


func tab_rect(i: int) -> Rect2:
	return Rect2(12.0 + i * (TAB.x + 6.0), CONTENT_Y, TAB.x, TAB.y)


func node_rect(n: Dictionary) -> Rect2:
	return Rect2(Vector2(52.0, GRID_Y) + Vector2(float(n["pos"][0]), float(n["pos"][1])) * STEP, NODE)


func choose_rect() -> Rect2:
	return Rect2(roundf((size.x - 180.0) / 2.0), size.y - 40.0, 180.0, 24.0)


func _content() -> void:
	var p: Progression = g.player.prog
	for i: int in TREES.size():
		var t: String = TREES[i]
		var label: String = "%s %d" % [GameData.passives["trees"][t]["name"], p.tree_spent(t)]
		button(tab_rect(i), label, t == tab or p.tree_open(t) or (p.mastery == "" and t != "lamplighter"))
	UiDraw.text(self, Vector2(0, CONTENT_Y + 38.0), "Passive points: %d" % p.passive_points(), UiDraw.GOLD if p.passive_points() > 0 else UiDraw.DIM,
		UiDraw.BODY, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 14.0)
	var tree: Dictionary = GameData.passives["trees"][tab]
	UiDraw.text(self, Vector2(14, CONTENT_Y + 38.0), String(tree["desc"]), UiDraw.DIM, UiDraw.SMALL)
	for row: int in ROWS:
		var req: int = _row_req(tree, row)
		if req >= 0:
			UiDraw.text(self, Vector2(10, GRID_Y + row * STEP.y + 22.0), "%d pts" % req, UiDraw.DIM, UiDraw.SMALL)
	for n: Dictionary in tree["nodes"]:
		_node(n)
	if tree.get("mastery", false):
		_mastery_footer(tree)


func _fit(s: String, w: float) -> String:
	return s if UiDraw.text_width(self, s, UiDraw.SMALL) <= w else s.split(" ")[-1]


## Points needed for a row of the tree (-1: empty row).
func _row_req(tree: Dictionary, row: int) -> int:
	for n: Dictionary in tree["nodes"]:
		if int(n["pos"][1]) == row:
			return int(n["req"])
	return -1


func _node(n: Dictionary) -> void:
	var r: Rect2 = node_rect(n)
	var p: Progression = g.player.prog
	var rk: int = int(p.passives.get(n["id"], 0))
	var open: bool = rk > 0 or p.passive_block(String(n["id"])) == ""
	UiDraw.box(self, r, Color(0.2, 0.12, 0.05) if rk > 0 else Color(0.05, 0.045, 0.07), UiDraw.FRAME_LIT if rk > 0 else (UiDraw.FRAME if open else UiDraw.LOCKED))
	if n.get("keystone", false):                     # keystones: a second, gold frame
		draw_rect(r.grow(-3.0), UiDraw.GOLD if open else UiDraw.LOCKED, false, 1.0)
	var gi: int = (GameData.sprites["icons"]["glyphs"] as Array).find(String(n["glyph"]))
	draw_texture_rect_region(_glyphs, Rect2(r.position + Vector2(5, 10), Vector2(GLYPH, GLYPH)), Rect2(gi * GLYPH, 0, GLYPH, GLYPH),
		Color.WHITE if open else Color(0.4, 0.4, 0.5))
	UiDraw.text(self, r.position + Vector2(25, 15), _fit(String(n["name"]), r.size.x - 29.0), UiDraw.TEXT if open else UiDraw.LOCKED, UiDraw.SMALL)
	UiDraw.text(self, r.position + Vector2(25, 28), "%d/%d" % [rk, int(n["max"])], UiDraw.GOLD if rk > 0 else UiDraw.DIM, UiDraw.SMALL)


func _mastery_footer(tree: Dictionary) -> void:
	var p: Progression = g.player.prog
	UiDraw.text(self, Vector2(0, size.y - 52.0), "Mastery bonus: " + String(tree["bonus_text"]), Color("8fdc6a"), UiDraw.BODY,
		HORIZONTAL_ALIGNMENT_CENTER, size.x)
	if p.mastery == "":
		var can: bool = p.can_choose_mastery()
		button(choose_rect(), "Choose %s" % tree["name"] if can else "Mastery at level %d" % int(GameData.player["mastery_level"]), can)
	elif p.mastery == tab:
		UiDraw.text(self, Vector2(0, size.y - 22.0), "Your mastery", UiDraw.GOLD, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, size.x)


func _click(at: Vector2, button_index: int) -> void:
	var p: Progression = g.player.prog
	for i: int in TREES.size():
		if tab_rect(i).has_point(at):
			tab = TREES[i]
			Audio.sfx("ui_click", -8.0)
			return
	if GameData.passives["trees"][tab].get("mastery", false) and choose_rect().has_point(at) and p.choose_mastery(tab):
		Audio.sfx("level_up", -6.0)
		g.hud.notice("You are a %s now" % GameData.passives["trees"][tab]["name"])
		return
	for n: Dictionary in GameData.passives["trees"][tab]["nodes"]:
		if node_rect(n).has_point(at):
			var ok: bool = p.add_passive(String(n["id"])) if button_index == MOUSE_BUTTON_LEFT else p.remove_passive(String(n["id"]))
			Audio.sfx("ui_click" if ok else "hiss", -6.0 if ok else -14.0)
			return


func _hover(at: Vector2) -> void:
	var p: Progression = g.player.prog
	for n: Dictionary in GameData.passives["trees"][tab]["nodes"]:
		if node_rect(n).has_point(at):
			var rows: Array = [String(n["name"]), ["Points %d / %d   (needs %d in this tree)" % [int(p.passives.get(n["id"], 0)), int(n["max"]), int(n["req"])], UiDraw.GOLD]]
			for k: String in n["stats"]:
				rows.append([GameData.stat_line(k, float(n["stats"][k])) + " per point", UiDraw.TEXT])
			if n.get("keystone", false):
				rows.append(["KEYSTONE", UiDraw.GOLD])
				for line: String in UiDraw.wrap(self, String(n["text"]), KEYSTONE_WRAP):
					rows.append([line, UiDraw.TEXT])
			var block: String = p.passive_block(String(n["id"]))
			if block != "" and block != "Maxed":
				rows.append([block, UiDraw.DOWN])
			rows.append(["Click: add   Right-click: refund", UiDraw.DIM])
			tip(rows)
			return
