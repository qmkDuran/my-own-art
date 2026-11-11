class_name CampPanel
extends Control
## The camp panel (opens when you rest; C toggles it while you are at camp): one row per team member with its
## portrait, bond meter, Pet and Feed (bond, once each per rest), and its three stats with the material each next
## level costs and a Raise button. Materials come from the wild creatures of each kind (the grind loop).

const W: float = 470.0
const HEAD: float = 30.0
const ROW: float = 84.0
const PORTRAIT: float = 46.0
const PAD: float = 8.0
const BTN := Vector2(46, 18)
const STAT_X: float = 196.0
const STAT_LINE: float = 22.0
const BAR_W: float = 120.0

var g: TamerGame


func setup(game: TamerGame) -> void:
	g = game
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	g.team.changed.connect(func() -> void:
		if visible:
			_rebuild())


func open() -> void:
	visible = true
	_rebuild()
	Audio.sfx("ui_open", -8.0)


func close() -> void:
	visible = false


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _rebuild() -> void:
	for c: Node in get_children():
		c.queue_free()
	size = Vector2(W, HEAD + PAD + g.team.members.size() * ROW + 28.0)
	for i: int in g.team.members.size():
		_row_buttons(g.team.members[i], Vector2(PAD, HEAD + PAD + i * ROW))
	_button("Close (C)", Vector2(W - 80.0 - PAD, size.y - 24.0), Vector2(80, 18), close)
	queue_redraw()


func _row_buttons(rec: CreatureRecord, at: Vector2) -> void:
	var care: Array[String] = ["pet", "feed"]
	for k: int in care.size():
		var kind: String = care[k]
		var b: Button = _button(kind.capitalize(), at + Vector2(PORTRAIT + 8.0 + k * (BTN.x + 6.0), 52.0), BTN, func() -> void:
			if g.camp.care(rec, kind):
				queue_redraw()
				_rebuild())
		b.disabled = (g.camp.petted if kind == "pet" else g.camp.fed).has(rec)
	var stats: Array = ["life", "power", "speed"]
	for k: int in stats.size():
		var stat: String = stats[k]
		var b: Button = _button("Raise", Vector2(W - PAD - BTN.x, at.y + k * STAT_LINE), BTN, func() -> void:
			if g.team.upgrade(rec, stat):
				g.guide.done("upgrade")
				Audio.sfx("level_up", -8.0, 1.4)
				TamerFx.word(g.camp.spot_of(rec), "%s up!" % TamerData.rule("upgrades." + stat + ".name"), Pal.c("gold")))
		var cost: int = rec.upgrade_cost(stat)
		b.disabled = cost < 0 or g.team.count(String(TamerData.rule("upgrades." + stat + ".material"))) < cost


func _button(text: String, at: Vector2, sz: Vector2, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = at
	b.size = sz
	b.add_theme_font_size_override("font_size", UiDraw.SMALL)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(on_press)
	add_child(b)
	return b


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	UiDraw.box(self, r, UiDraw.PANEL)
	UiDraw.title_bar(self, r, "Camp")
	for i: int in g.team.members.size():
		_row(g.team.members[i], Vector2(PAD, HEAD + PAD + i * ROW))
	UiDraw.text(self, Vector2(PAD, size.y - 10.0), "Wild kinds drop the materials: devils (Life), wolves (Power), aye-ayes (Speed).",
		UiDraw.DIM, UiDraw.SMALL)


func _row(rec: CreatureRecord, at: Vector2) -> void:
	CreaturePortrait.draw_in(self, Rect2(at, Vector2(PORTRAIT, PORTRAIT)), rec)
	var x: float = at.x + PORTRAIT + 8.0
	UiDraw.text(self, Vector2(x, at.y + 10.0), rec.display_name(), Pal.c("gold") if rec.shiny else UiDraw.TEXT, UiDraw.BODY)
	UiDraw.text(self, Vector2(x, at.y + 22.0), "Bond %d / %d" % [roundi(rec.bond), int(TamerData.rule("bond.max"))], Pal.c("rose"), UiDraw.SMALL)
	var bar := Rect2(Vector2(x, at.y + 28.0), Vector2(BAR_W, 4.0))
	draw_rect(bar.grow(1.0), UiDraw.INK)
	draw_rect(Rect2(bar.position, Vector2(BAR_W * rec.bond_frac(), 4.0)), Pal.c("rose"))
	UiDraw.text(self, Vector2(x, at.y + 44.0), "Bond move unlocked (T)" if rec.bond_move_ready() else "Bond move at %d" % int(TamerData.rule("bond.unlock")),
		Pal.c("sun") if rec.bond_move_ready() else UiDraw.DIM, UiDraw.SMALL)
	for k: int in 3:
		_stat(rec, ["life", "power", "speed"][k], Vector2(at.x + STAT_X, at.y + k * STAT_LINE + 13.0))
	draw_line(Vector2(PAD, at.y + ROW - 6.0), Vector2(W - PAD, at.y + ROW - 6.0), Color(UiDraw.FRAME, 0.5))


func _stat(rec: CreatureRecord, stat: String, at: Vector2) -> void:
	var U: Dictionary = TamerData.rule("upgrades." + stat)
	var lvl: int = int(rec.upgrades[stat])
	UiDraw.text(self, at, "%s  +%d%%" % [U["name"], roundi(float(U["per_level"]) * lvl * 100.0)], UiDraw.TEXT, UiDraw.SMALL)
	var cost: int = rec.upgrade_cost(stat)
	var mat: String = String(U["material"])
	var text: String = "maxed" if cost < 0 else "%d/%d %s" % [g.team.count(mat), cost, TamerData.rule("materials." + mat + ".name")]
	var ok: bool = cost >= 0 and g.team.count(mat) >= cost
	UiDraw.text(self, at + Vector2(82, 0), text, UiDraw.UP if ok else UiDraw.DIM, UiDraw.SMALL)
