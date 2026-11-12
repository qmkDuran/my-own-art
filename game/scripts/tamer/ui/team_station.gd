class_name TeamStation
extends Control
## The Gate Hall's team station (F next to it): pick 3 of the 6 creatures, set their level (5 / 15 / 30), and
## choose each one's 4 active moves from what it has learned (click a slot to cycle through the moves it knows).
## At camp the same panel opens for one creature's moves only. The picks become your team when it closes.

const W: float = 600.0
const HEAD: float = 30.0
const PAD: float = 10.0
const PICK := Vector2(56, 56)
const CHIP := Vector2(44, 18)
const PICK_GAP: float = 14.0
const ROW: float = 58.0
const SLOT := Vector2(108, 40)
const PORTRAIT: float = 44.0
const PICKS: int = 3

var g: TamerGame
var roster: Dictionary = {}             ## species id -> CreatureRecord (the station's six)
var picks: Array[String] = []
var level: int = 5
var only: CreatureRecord                ## camp: just this one's moves
var _hover: Array = []                  ## [move id, record] under the mouse


func setup(game: TamerGame) -> void:
	g = game
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)
	var b := Button.new()
	b.text = "Done (Esc)"
	b.size = Vector2(90, 20)
	b.add_theme_font_size_override("font_size", UiDraw.SMALL)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(close)
	b.name = "Done"
	add_child(b)


## The station's record for a species, made at the current level the first time it is asked for.
func record(id: String) -> CreatureRecord:
	if not roster.has(id):
		var r := CreatureRecord.make(id, 1, false)
		r.growth.set_level(level)
		roster[id] = r
	return roster[id]


## Picks a team and level at once (the demo's start, tests) and makes it your team.
func choose(ids: Array, lvl: int) -> void:
	picks.clear()
	for id: Variant in ids:
		picks.append(String(id))
	set_level(lvl)
	apply()


func open() -> void:
	only = null
	picks.clear()
	for r: CreatureRecord in g.team.members:
		if roster.values().has(r):
			picks.append(r.species_id)
	_show()
	g.guide.done("station")


## Camp: the moves of one creature.
func open_moves(rec: CreatureRecord) -> void:
	only = rec
	_show()


func _show() -> void:
	visible = true
	size = Vector2(W, _height())
	(get_node("Done") as Button).position = Vector2(W - 90.0 - PAD, size.y - 28.0)
	Audio.sfx("ui_open", -8.0)
	queue_redraw()


func _height() -> float:
	if only != null:
		return HEAD + PAD + ROW + 36.0
	return HEAD + PAD + PICK.y + 30.0 + CHIP.y + 16.0 + PICKS * ROW + 36.0


func close() -> void:
	if not visible:
		return
	visible = false
	if only == null:
		apply()


## Your team becomes the picks (in pick order), all at the chosen level; your creature comes out again.
func apply() -> void:
	if picks.is_empty():
		return
	var recs: Array[CreatureRecord] = []
	for id: String in picks:
		recs.append(record(id))
	if recs == g.team.members:
		return
	g.field.recall_now()
	g.team.replace(recs)
	g.field.summon(0, false)


func toggle_pick(id: String) -> void:
	if picks.has(id):
		picks.erase(id)
	elif picks.size() < PICKS:
		picks.append(id)
	Audio.sfx("ui_click", -8.0)
	queue_redraw()


func set_level(lvl: int) -> void:
	level = lvl
	for id: String in roster:
		(roster[id] as CreatureRecord).growth.set_level(lvl)
	queue_redraw()


## The next learned move (not already in another slot) into slot `i`.
func cycle_move(rec: CreatureRecord, i: int) -> void:
	var known: Array[String] = rec.growth.learned()
	var at: int = known.find(rec.growth.active[i])
	for k: int in range(1, known.size() + 1):
		var cand: String = known[(at + k) % known.size()]
		if not rec.growth.active.has(cand):
			rec.growth.set_move(i, cand)
			break
	Audio.sfx("ui_click", -8.0, 1.2)
	queue_redraw()


func _rows() -> Array[CreatureRecord]:
	var out: Array[CreatureRecord] = []
	if only != null:
		out.append(only)
	else:
		for id: String in picks:
			out.append(record(id))
	return out


# --- layout (shared by drawing and clicking) ---

func _pick_rect(i: int) -> Rect2:
	return Rect2(Vector2(PAD + i * (PICK.x + PICK_GAP), HEAD + PAD), PICK)


func _chip_rect(i: int) -> Rect2:
	return Rect2(Vector2(PAD + 50.0 + i * (CHIP.x + 6.0), HEAD + PAD + PICK.y + 30.0), CHIP)


func _rows_top() -> float:
	return HEAD + PAD if only != null else HEAD + PAD + PICK.y + 30.0 + CHIP.y + 16.0


func _slot_rect(row: int, i: int) -> Rect2:
	return Rect2(Vector2(PAD + PORTRAIT + 120.0 + i * (SLOT.x + 4.0), _rows_top() + row * ROW), SLOT)


func _on_input(event: InputEvent) -> void:
	var mm := event as InputEventMouseMotion
	if mm != null:
		_hover = _move_under(mm.position)
		queue_redraw()
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if only == null:
		var ids: Array = TamerData.species_all["species"].keys()
		for i: int in ids.size():
			if _pick_rect(i).has_point(mb.position):
				toggle_pick(String(ids[i]))
		var levels: Array = TamerData.rule("progression.levels")
		for i: int in levels.size():
			if _chip_rect(i).has_point(mb.position):
				set_level(int(levels[i]))
	var rows: Array[CreatureRecord] = _rows()
	for r: int in rows.size():
		for i: int in 4:
			if _slot_rect(r, i).has_point(mb.position):
				cycle_move(rows[r], i)
	accept_event()


func _move_under(p: Vector2) -> Array:
	var rows: Array[CreatureRecord] = _rows()
	for r: int in rows.size():
		for i: int in 4:
			if _slot_rect(r, i).has_point(p):
				return [String(rows[r].growth.active[i]), rows[r]]
	return []


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	UiDraw.box(self, box, UiDraw.PANEL)
	UiDraw.title_bar(self, box, "Team station" if only == null else "%s: moves" % only.display_name())
	if only == null:
		_draw_picks()
	var rows: Array[CreatureRecord] = _rows()
	for r: int in rows.size():
		_draw_row(rows[r], r)
	var hint: String = "Click a move to cycle through the moves it knows. Hold status moves in battle."
	UiDraw.text(self, Vector2(PAD, size.y - 14.0), hint, UiDraw.DIM, UiDraw.SMALL)
	if not _hover.is_empty():
		var rec: CreatureRecord = _hover[1]
		UiDraw.tooltip(self, get_local_mouse_position(), MoveText.rows(self, String(_hover[0]), rec.power(), rec.element()))


func _draw_picks() -> void:
	var ids: Array = TamerData.species_all["species"].keys()
	for i: int in ids.size():
		var id: String = String(ids[i])
		var r: Rect2 = _pick_rect(i)
		CreaturePortrait.draw_in(self, r, record(id))
		var k: int = picks.find(id)
		draw_rect(r.grow(1.0), UiDraw.FRAME_LIT if k >= 0 else UiDraw.FRAME, false, 2.0 if k >= 0 else 1.0)
		if k >= 0:
			UiDraw.text(self, r.position + Vector2(3, 10), str(k + 1), UiDraw.GOLD, UiDraw.BODY)
		else:
			draw_rect(r, Color(0, 0, 0, 0.35))
		var label: PackedStringArray = UiDraw.wrap(self, String(TamerData.species(id)["name"]), r.size.x + 14.0, UiDraw.SMALL)
		for j: int in label.size():
			UiDraw.text(self, r.position + Vector2(-7, r.size.y + 11.0 + j * 9.0), label[j], UiDraw.TEXT, UiDraw.SMALL,
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 14.0)
	UiDraw.text(self, Vector2(PAD + 6.0 * (PICK.x + PICK_GAP) + 10.0, HEAD + PAD + 20.0), "Pick %d (%d/%d)" % [PICKS, picks.size(), PICKS],
		UiDraw.GOLD, UiDraw.BODY)
	var levels: Array = TamerData.rule("progression.levels")
	UiDraw.text(self, Vector2(PAD, _chip_rect(0).position.y + 13.0), "Level", UiDraw.TEXT, UiDraw.BODY)
	for i: int in levels.size():
		var c: Rect2 = _chip_rect(i)
		var on: bool = int(levels[i]) == level
		UiDraw.box(self, c, Pal.c("earth") if on else UiDraw.PANEL_DEEP, UiDraw.FRAME_LIT if on else UiDraw.FRAME)
		UiDraw.text(self, c.position + Vector2(0, 13), str(int(levels[i])), UiDraw.GOLD if on else UiDraw.TEXT, UiDraw.BODY,
			HORIZONTAL_ALIGNMENT_CENTER, c.size.x)


func _draw_row(rec: CreatureRecord, row: int) -> void:
	var y: float = _rows_top() + row * ROW
	CreaturePortrait.draw_in(self, Rect2(Vector2(PAD, y), Vector2(PORTRAIT, PORTRAIT)), rec)
	UiDraw.text(self, Vector2(PAD + PORTRAIT + 6.0, y + 12.0), rec.display_name(), Pal.c("gold") if rec.shiny else UiDraw.TEXT, UiDraw.BODY)
	UiDraw.text(self, Vector2(PAD + PORTRAIT + 6.0, y + 25.0), "Lv %d, %d moves" % [rec.level, rec.growth.learned().size()],
		UiDraw.DIM, UiDraw.SMALL)
	for i: int in 4:
		var s: Rect2 = _slot_rect(row, i)
		var id: String = String(rec.growth.active[i])
		var m: Dictionary = TamerData.move(id)
		var el: String = MoveText.element_of(id, rec.element())
		UiDraw.box(self, s, UiDraw.PANEL_DEEP, TamerData.color(el, "dark"))
		MoveIcon.glyph(self, Rect2(s.position + Vector2(4, 4), Vector2(18, 18)), String(m.get("icon", "slash")),
			TamerData.color(el, "core"), TamerData.color(el, "light"))
		UiDraw.text(self, s.position + Vector2(26, 14), String(m["name"]), TamerData.color(el, "light"), UiDraw.SMALL)
		UiDraw.text(self, s.position + Vector2(26, 27), String(m["type"]).capitalize(), UiDraw.DIM, UiDraw.SMALL)
		UiDraw.text(self, s.position + Vector2(4, 37), TamerKeys.MOVE_LABELS[i], UiDraw.GOLD, UiDraw.SMALL)
