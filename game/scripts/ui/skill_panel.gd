class_name SkillPanel
extends GamePanel
## Skills and their specialisation trees. Left: your skills (level, points free). Right: the selected skill's
## tree — nodes in rows by the points they need, lines to the node they grow from; click to add a point,
## right-click to refund. Below: put the skill on a hotbar key.

const LIST_W: float = 150.0
const ROW_H: float = 27.0
const NODE := Vector2(76, 34)
const STEP := Vector2(86, 64)
const TREE_Y: float = 92.0
const ICON: float = 24.0
const LIST_ICON: float = 23.0
const GLYPH: float = 16.0
const ORDER: Array[String] = ["wickbolt", "flare", "lantern_toss", "moth_swarm", "eclipse", "noon", "kindle", "tether", "glass_ward",
	"cinder_rain", "wick_trap", "lull", "dash"]

var selected: String = "wickbolt"
var _skills_tex: Texture2D
var _glyphs: Texture2D
var _art := TreeArt.new()
var _over: String = ""                ## id of the node under the mouse


func _ready() -> void:
	_skills_tex = PropSprite.tex("res://art/ui/skills.png")
	_glyphs = PropSprite.tex("res://art/ui/glyphs.png")


func list_rect(i: int) -> Rect2:
	return Rect2(8, CONTENT_Y + 2.0 + i * ROW_H, LIST_W - 8.0, ROW_H - 2.0)


func node_rect(n: Dictionary) -> Rect2:
	var origin := Vector2(LIST_W + 16.0, TREE_Y)
	return Rect2(origin + Vector2(float(n["pos"][0]), float(n["pos"][1])) * STEP, NODE)


## The framed ground the selected skill's tree stands on.
func tree_rect() -> Rect2:
	return Rect2(LIST_W + 6.0, TREE_Y - 10.0, size.x - LIST_W - 12.0, size.y - TREE_Y - 40.0)


func key_rect(i: int) -> Rect2:
	return Rect2(LIST_W + 20.0 + i * 46.0, size.y - 34.0, 40.0, 22.0)


func _content() -> void:
	for i: int in ORDER.size():
		_list_row(i, ORDER[i])
	draw_line(Vector2(LIST_W, CONTENT_Y), Vector2(LIST_W, size.y - 8.0), Color(UiDraw.FRAME, 0.5))
	_tree_header()
	var nodes: Array = GameData.skill(selected)["nodes"]
	var t: float = Time.get_ticks_msec() / 1000.0
	_art.backdrop(self, tree_rect(), t)
	if nodes.is_empty():
		UiDraw.text(self, tree_rect().position + Vector2(0, tree_rect().size.y / 2.0), "No tree: this skill does not specialise.",
			UiDraw.DIM, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, tree_rect().size.x)
	for l: Array in TreeArt.links(nodes):
		_art.connector(self, node_rect(l[0]).get_center(), node_rect(l[1]).get_center(), _rank(l[0]) > 0 and _rank(l[1]) > 0, t)
	for n: Dictionary in nodes:
		_node(n, t)
	_art.draw_sparks(self, get_process_delta_time())
	_spec_button()
	if g.player.prog.skills.has(selected) and selected != "dash":
		UiDraw.text(self, Vector2(LIST_W + 20.0, size.y - 40.0), "Hotbar key:", UiDraw.DIM, UiDraw.SMALL)
		for i: int in InputSetup.SLOTS.size():
			var k: String = InputSetup.SLOTS[i]
			button(key_rect(i), InputSetup.SLOT_LABELS[k], g.player.prog.slots[k] != selected)
	if SpecSlotsView.needs_card():
		SpecSlotsView.draw_card(self, tree_rect())


func spec_rect() -> Rect2:
	return Rect2(size.x - 134.0, CONTENT_Y + 4.0, 120.0, 18.0)


## Specialise / Forget, and how many slots are in use.
func _spec_button() -> void:
	var p: Progression = g.player.prog
	SpecSlotsView.draw_row(self, slots_origin(), p, _skills_tex, Time.get_ticks_msec() / 1000.0)
	if not p.skills.has(selected) or GameData.skill(selected)["nodes"].is_empty():
		return
	var label: String = "Forget (resets)" if p.is_specialised(selected) else "Specialise"
	button(spec_rect(), label, p.is_specialised(selected) or p.can_specialise(selected))


## Where the row of specialisation sockets starts (under the Specialise button).
func slots_origin() -> Vector2:
	return Vector2(spec_rect().end.x - SpecSlotsView.row_width(), spec_rect().end.y + 6.0)


func _list_row(i: int, id: String) -> void:
	var r: Rect2 = list_rect(i)
	var learned: bool = g.player.prog.skills.has(id) or id == "dash"
	UiDraw.box(self, r, Color(0.16, 0.11, 0.07) if id == selected else Color(0.06, 0.05, 0.08), UiDraw.FRAME_LIT if id == selected else UiDraw.FRAME)
	var icon: int = int(GameData.skill(id)["icon"])
	draw_texture_rect_region(_skills_tex, Rect2(r.position + Vector2(2, 1), Vector2(LIST_ICON, LIST_ICON)), Rect2(icon * ICON, 0, ICON, ICON),
		Color.WHITE if learned else Color(0.4, 0.4, 0.5))
	UiDraw.text(self, r.position + Vector2(28, 11), String(GameData.skill(id)["name"]), UiDraw.TEXT if learned else UiDraw.LOCKED)
	var sub: String = _sub(id, learned)
	UiDraw.text(self, r.position + Vector2(28, 22), sub, UiDraw.GOLD if g.player.prog.spec_points(id) > 0 else UiDraw.DIM, UiDraw.SMALL)


func _sub(id: String, learned: bool) -> String:
	if not learned:
		return "learn at level %d" % int(Progression.LEARN.get(id, 0))
	if id == "dash":
		return "movement"
	if not g.player.prog.is_specialised(id):
		return "not specialised"
	var pts: int = g.player.prog.spec_points(id)
	return "level %d%s" % [g.player.prog.skill_level(id), "   %d pts" % pts if pts > 0 else ""]


func _tree_header() -> void:
	var p: Progression = g.player.prog
	var x: float = LIST_W + 14.0
	var d: Dictionary = GameData.skill(selected)
	UiDraw.text(self, Vector2(x, CONTENT_Y + 14.0), "%s  -  level %d" % [d["name"], p.skill_level(selected)], UiDraw.GOLD)
	if p.skills.has(selected) and not d["nodes"].is_empty():
		var xr := Rect2(x, CONTENT_Y + 22.0, size.x - x - 150.0, 4.0)
		var sd: Dictionary = p.skills[selected]
		draw_rect(xr.grow(1.0), UiDraw.INK)
		draw_rect(Rect2(xr.position, Vector2(xr.size.x * float(sd["xp"]) / p.skill_xp_to_next(int(sd["level"])), xr.size.y)), Pal.c("violet_lt"))
		var pts: int = p.spec_points(selected)
		UiDraw.text(self, Vector2(x, CONTENT_Y + 42.0), "Points to spend: %d" % pts, UiDraw.GOLD if pts > 0 else UiDraw.DIM)


func _rank(n: Dictionary) -> int:
	return g.player.prog.node_rank(selected, String(n["id"]))


func _node(n: Dictionary, t: float) -> void:
	var r: Rect2 = node_rect(n)
	var rk: int = _rank(n)
	var open: bool = g.player.prog.spec_block(selected, String(n["id"])) == "" or rk > 0
	_art.node_frame(self, r, TreeArt.kind_of(n), rk > 0, open, _over == n["id"], t)
	var gi: int = (GameData.sprites["icons"]["glyphs"] as Array).find(TreeArt.glyph_for(n["vals"]))
	draw_texture_rect_region(_glyphs, Rect2(r.position + Vector2(4, 4), Vector2(GLYPH, GLYPH)), Rect2(gi * GLYPH, 0, GLYPH, GLYPH),
		Color.WHITE if open else Color(0.4, 0.4, 0.5))
	UiDraw.text(self, r.position + Vector2(GLYPH + 6.0, 14), _fit(String(n["name"]), r.size.x - GLYPH - 9.0), UiDraw.TEXT if open else UiDraw.LOCKED,
		UiDraw.SMALL)
	UiDraw.text(self, r.position + Vector2(0, 29), "%d/%d" % [rk, int(n["max"])], UiDraw.GOLD if rk > 0 else UiDraw.DIM, UiDraw.SMALL,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


## The node's name if it fits the box, else its first word (the tooltip has the full name).
func _fit(s: String, w: float) -> String:
	return s if UiDraw.text_width(self, s, UiDraw.SMALL) <= w else s.split(" ")[0]


func _click(at: Vector2, button_index: int) -> void:
	if SpecSlotsView.needs_card():
		if SpecSlotsView.button_rect(SpecSlotsView.card_rect(tree_rect(), self)).has_point(at):
			SpecSlotsView.dismiss()
			Audio.sfx("ui_click", -8.0)
		return
	for i: int in ORDER.size():
		if list_rect(i).has_point(at):
			selected = ORDER[i]
			Audio.sfx("ui_click", -8.0)
			return
	if spec_rect().has_point(at) and g.player.prog.skills.has(selected):
		if g.player.prog.is_specialised(selected):
			g.player.prog.forget(selected)
		else:
			g.player.prog.specialise(selected)
		Audio.sfx("ui_click", -6.0)
		return
	for n: Dictionary in GameData.skill(selected)["nodes"]:
		if node_rect(n).has_point(at):
			var add: bool = button_index == MOUSE_BUTTON_LEFT
			var ok: bool = g.player.prog.add_spec(selected, String(n["id"])) if add else g.player.prog.remove_spec(selected, String(n["id"]))
			Audio.sfx("ui_click" if ok else "hiss", -6.0 if ok else -14.0)
			if ok and add:
				_art.burst(node_rect(n).get_center())
			return
	for i: int in InputSetup.SLOTS.size():
		if key_rect(i).has_point(at) and g.player.prog.skills.has(selected) and selected != "dash":
			g.player.prog.set_slot(InputSetup.SLOTS[i], selected)
			Audio.sfx("ui_click", -8.0)


func _hover(at: Vector2) -> void:
	_over = ""
	if SpecSlotsView.needs_card():
		return
	for i: int in (GameData.player["skill_slot_levels"] as Array).size():
		if SpecSlotsView.socket_rect(slots_origin(), i).has_point(at):
			tip(SpecSlotsView.socket_tip(g.player.prog, i))
			return
	for i: int in ORDER.size():
		if list_rect(i).has_point(at):
			tip(SkillText.rows(self, g.player, ORDER[i]))
			return
	for n: Dictionary in GameData.skill(selected)["nodes"]:
		if node_rect(n).has_point(at):
			_over = String(n["id"])
			tip(SkillText.node_rows(self, g.player, selected, n))
			return
