class_name SanctuaryPanel
extends Control
## The Sanctuary (at camp): your team (up to six) on top, the synced creatures waiting in the Sanctuary below. Click
## a team member to send it to the Sanctuary, or a Sanctuary creature to bring it into the team.

const W: float = 440.0
const HEAD: float = 30.0
const PAD: float = 8.0
const CELL := Vector2(64, 74)
const COLS: int = 6
const PORTRAIT: float = 44.0

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


func _rebuild() -> void:
	for c: Node in get_children():
		c.queue_free()
	var rows: int = 1 + maxi(1, ceili(g.team.sanctuary.size() / float(COLS)))
	size = Vector2(W, HEAD + PAD + rows * CELL.y + 50.0)
	for i: int in g.team.members.size():
		var rec: CreatureRecord = g.team.members[i]
		_cell(rec, _at(0, i), "To Sanctuary", func() -> void: g.team.to_sanctuary(rec), i != g.team.active and g.team.members.size() > 1)
	for i: int in g.team.sanctuary.size():
		var rec: CreatureRecord = g.team.sanctuary[i]
		_cell(rec, _at(1 + i / COLS, i % COLS), "To team", func() -> void: g.team.from_sanctuary(rec), not g.team.full())
	var b := _button("Close", Vector2(W - 70.0 - PAD, size.y - 24.0), Vector2(70, 18))
	b.pressed.connect(close)
	queue_redraw()


func _at(row: int, col: int) -> Vector2:
	return Vector2(PAD + col * (CELL.x + 6.0), HEAD + PAD + 14.0 + row * (CELL.y + 16.0))


func _cell(_rec: CreatureRecord, at: Vector2, label: String, act: Callable, ok: bool) -> void:
	var b := _button(label, at + Vector2(0, PORTRAIT + 12.0), Vector2(CELL.x, 16))
	b.disabled = not ok
	b.pressed.connect(func() -> void:
		act.call()
		Audio.sfx("ui_click", -8.0))


func _button(text: String, at: Vector2, sz: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = at
	b.size = sz
	b.add_theme_font_size_override("font_size", UiDraw.SMALL)
	b.focus_mode = Control.FOCUS_NONE
	add_child(b)
	return b


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	UiDraw.box(self, r, UiDraw.PANEL)
	UiDraw.title_bar(self, r, "Sanctuary")
	UiDraw.text(self, Vector2(PAD, HEAD + PAD + 8.0), "Team (%d / %d)" % [g.team.members.size(), int(TamerData.rule("team_max"))], UiDraw.GOLD, UiDraw.SMALL)
	for i: int in g.team.members.size():
		_portrait(g.team.members[i], _at(0, i))
	var y: float = _at(1, 0).y - 6.0
	UiDraw.text(self, Vector2(PAD, y), "Sanctuary (%d)" % g.team.sanctuary.size(), UiDraw.GOLD, UiDraw.SMALL)
	if g.team.sanctuary.is_empty():
		UiDraw.text(self, Vector2(PAD, y + 30.0), "Empty. Creatures you sync beyond your first three come here.", UiDraw.DIM, UiDraw.SMALL)
	for i: int in g.team.sanctuary.size():
		_portrait(g.team.sanctuary[i], _at(1 + i / COLS, i % COLS))


func _portrait(rec: CreatureRecord, at: Vector2) -> void:
	var cell := Rect2(at + Vector2((CELL.x - PORTRAIT) * 0.5, 0), Vector2(PORTRAIT, PORTRAIT))
	CreaturePortrait.draw_in(self, cell, rec)
	UiDraw.text(self, at + Vector2(0, PORTRAIT + 9.0), "%s %d" % [String(rec.data()["name"]).split(" ")[0], rec.level],
		Pal.c("gold") if rec.shiny else UiDraw.TEXT, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, CELL.x)
