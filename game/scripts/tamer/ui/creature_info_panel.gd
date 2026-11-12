class_name CreatureInfoPanel
extends Control
## Everything about one creature (I, a click on the team strip, or Info at camp): its portrait, element and what
## that element beats and fears, role, level, stats and experience, its home terrain, and its four active moves
## (Q W E R) with their icon, type, element, what they do and their numbers.

const W: float = 600.0
const HEAD: float = 30.0
const PAD: float = 8.0
const PORTRAIT: float = 56.0
const MOVE_H: float = 48.0
const ICON: float = 26.0
const TEXT_X: float = 42.0
const LINE: float = 11.0

var g: TamerGame
var rec: CreatureRecord


func setup(game: TamerGame) -> void:
	g = game
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(W, HEAD + PAD * 2.0 + PORTRAIT + 10.0 + 4 * MOVE_H + 24.0)
	var b := Button.new()
	b.text = "Close (I)"
	b.size = Vector2(80, 18)
	b.position = Vector2(W - 80.0 - PAD, size.y - 24.0)
	b.add_theme_font_size_override("font_size", UiDraw.SMALL)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(close)
	add_child(b)


func open(r: CreatureRecord) -> void:
	if r == null:
		return
	rec = r
	visible = true
	Audio.sfx("ui_open", -8.0)
	queue_redraw()


func close() -> void:
	visible = false


func toggle(r: CreatureRecord) -> void:
	if visible and r == rec:
		close()
	else:
		open(r)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if rec == null:
		return
	var r := Rect2(Vector2.ZERO, size)
	UiDraw.box(self, r, UiDraw.PANEL)
	UiDraw.title_bar(self, r, rec.display_name())
	var top: float = HEAD + PAD
	CreaturePortrait.draw_in(self, Rect2(Vector2(PAD, top), Vector2(PORTRAIT, PORTRAIT)), rec)
	_facts(Vector2(PAD + PORTRAIT + 10.0, top + 9.0))
	var ids: Array = rec.moves()
	for i: int in ids.size():
		_move(String(ids[i]), TamerKeys.MOVE_LABELS[i], Vector2(PAD, top + PORTRAIT + 10.0 + i * MOVE_H))


func _facts(at: Vector2) -> void:
	var d: Dictionary = rec.data()
	var el: Dictionary = TamerData.element(rec.element())
	UiDraw.text(self, at, "%s  -  %s  -  %s  -  Lv %d" % [el["name"], d["role"], String(d["nature"]).capitalize(), rec.level],
		TamerData.color(rec.element(), "light"), UiDraw.BODY)
	var beats: String = ", ".join((el["strong"] as Array).map(func(e: String) -> String: return TamerData.element(e)["name"]))
	var fears: String = ", ".join((el["weak"] as Array).map(func(e: String) -> String: return TamerData.element(e)["name"]))
	UiDraw.text(self, at + Vector2(0, LINE + 2.0), "Strong against %s.  Weak against %s." % [beats, fears], UiDraw.TEXT, UiDraw.SMALL)
	UiDraw.text(self, at + Vector2(0, LINE * 2.0 + 4.0), "Life %d / %d   Power x%.2f   Speed %d   XP %d / %d" % [
		roundi(maxf(rec.life, 0.0)), roundi(rec.max_life()), rec.power(), roundi(rec.speed()), roundi(rec.growth.xp),
		roundi(CreatureGrowth.xp_to_next(rec.level))], UiDraw.TEXT, UiDraw.SMALL)
	UiDraw.text(self, at + Vector2(0, LINE * 3.0 + 6.0), "Home: " + String(d["home"]["text"]), Pal.c("leaf_lt"), UiDraw.SMALL)


func _move(id: String, key: String, at: Vector2) -> void:
	var m: Dictionary = TamerData.move(id)
	var el: String = MoveText.element_of(id, rec.element())
	MoveIcon.draw_slot(self, Rect2(at + Vector2(0, 4), Vector2(ICON, ICON)), id, el, key, 0.0, 0.0)
	var x: float = at.x + TEXT_X
	var title: String = "%s  (%s, %s)" % [m["name"], String(m["type"]).capitalize(), TamerData.element(el)["name"]]
	UiDraw.text(self, Vector2(x, at.y + 10.0), title, TamerData.color(el, "light"), UiDraw.BODY)
	UiDraw.text(self, Vector2(x, at.y + 22.0), String(m.get("desc", "")), UiDraw.TEXT, UiDraw.SMALL)
	var nums: Array[String] = []
	for row: Array in MoveText.numbers(m, rec.power()):
		nums.append(String(row[0]))
	UiDraw.text(self, Vector2(x, at.y + 33.0), ", ".join(nums), UiDraw.DIM, UiDraw.SMALL)
	draw_line(Vector2(PAD, at.y + MOVE_H - 4.0), Vector2(W - PAD, at.y + MOVE_H - 4.0), Color(UiDraw.FRAME, 0.4))
