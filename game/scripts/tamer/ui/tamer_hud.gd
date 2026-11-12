class_name TamerHud
extends CanvasLayer
## The prototype's screen: the tracker (what to try next) top left, materials top right, notices top centre, the
## story caption above the cards; bottom left the trainer's commands (A S D G), the two items and the "controlling"
## badge (the trainer is never hurt, so there is no life to show);
## bottom centre the active creature's card; bottom right the team strip; the camp panel when resting. Laid out
## from the viewport size every frame (no fixed coordinates).

const LAYER: int = 10
const MARGIN: float = 10.0
const CMD: float = 30.0
const CMD_ROW: float = 48.0             ## height of the command row (slots, keys under them)
const ITEM: float = 26.0
const TRACKER_W: float = 300.0
const NOTICE_TIME: float = 4.0
const NOTICE_MAX: int = 3
const NOTICE_AT: float = 0.24           ## share of the screen height where notices start (clear of the tracker)
const CAPTION_TIME: float = 6.0
const LINE: float = 13.0
const BADGE := Vector2(150, 18)
const VIGNETTE_TIME: float = 0.35
const VICTORY_TIME: float = 3.5
const CALLOUT_TIME: float = 1.6

var g: TamerGame
var _fade := ColorRect.new()
var _vignette := TextureRect.new()
var _victory: Array[String] = []
var _victory_t: float = 0.0
var _callout: String = ""               ## a move's name the first time it is used, just above the creature card
var _callout_col: Color
var _callout_t: float = 0.0
var card := CreatureCard.new()
var strip := TeamStrip.new()
var camp_panel := CampPanel.new()
var info_panel := CreatureInfoPanel.new()
var tracker_hidden: bool = false
var forced_tip: int = -1                ## tests and stills: show this card slot's tooltip as if hovered
var _canvas := Control.new()
var _tip := Control.new()               ## tooltips, above everything
var _notices: Array = []                ## [text, time left]
var _caption: String = ""
var _caption_t: float = 0.0


func setup(game: TamerGame) -> void:
	g = game
	layer = LAYER
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_canvas)
	add_child(_canvas)
	card.setup(g)
	add_child(card)
	strip.setup(g)
	add_child(strip)
	camp_panel.setup(g)
	add_child(camp_panel)
	info_panel.setup(g)
	add_child(info_panel)
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.texture = _vignette_tex()
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.modulate.a = 0.0
	add_child(_vignette)
	move_child(_vignette, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.color = Color(UiDraw.INK, 0.0)
	add_child(_fade)
	_tip.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.draw.connect(_draw_tip)
	add_child(_tip)


## The screen fades to ink, `then` runs while it is dark, and it fades back (the white-out retreat).
func fade(time: float, hold: float, then: Callable) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, time)
	tw.tween_callback(then)
	tw.tween_interval(hold)
	tw.tween_property(_fade, "color:a", 0.0, time)


func _vignette_tex() -> GradientTexture2D:
	var gr := Gradient.new()
	gr.set_color(0, Color(UiDraw.INK, 0.0))
	gr.add_point(0.62, Color(UiDraw.INK, 0.0))
	gr.set_color(gr.get_point_count() - 1, Color(UiDraw.INK, 0.55))
	var t := GradientTexture2D.new()
	t.gradient = gr
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 1.0)
	t.width = 256
	t.height = 144
	return t


func command_origin() -> Vector2:
	return Vector2(MARGIN, _canvas.size.y - MARGIN - CMD_ROW + 8.0)


func command_rect(i: int) -> Rect2:
	return Rect2(command_origin() + Vector2(i * (CMD + 6.0), 0), Vector2(CMD, CMD))


## The trainer's four commands with their cooldowns, under "TRAINER".
func _commands(at: Vector2) -> void:
	UiDraw.text(_canvas, at + Vector2(0, -4), "TRAINER", UiDraw.GOLD, UiDraw.SMALL)
	for i: int in TrainerCommands.IDS.size():
		var id: String = TrainerCommands.IDS[i]
		var d: Dictionary = g.commands.data(id)
		var r: Rect2 = command_rect(i)
		UiDraw.box(_canvas, r, UiDraw.PANEL_DEEP, Pal.c(String(d["color"])))
		MoveIcon.glyph(_canvas, r.grow(-5.0), String(d["icon"]), Pal.c(String(d["color"])), Pal.c("sun"))
		var cd: float = g.commands.cooldown_frac(id)
		if cd > 0.0:
			_canvas.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * cd)), Color(0, 0, 0, 0.6))
		UiDraw.text(_canvas, r.position + Vector2(2, r.size.y + 9.0), String(d["key"]), UiDraw.DIM, UiDraw.SMALL)


func panel_open() -> bool:
	return camp_panel.visible or info_panel.visible


## Hovering a move on the card shows what it does; hovering the team strip says it can be clicked.
func _draw_tip() -> void:
	var mouse: Vector2 = _tip.get_local_mouse_position()
	if forced_tip >= 0:
		mouse = card.position + card._slot_rect(forced_tip).get_center()
	var hit: Array = card.move_at(mouse - card.position)
	var rec: CreatureRecord = g.team.current()
	if not hit.is_empty() and rec != null:
		var rows: Array = MoveText.rows(_tip, String(hit[0]), rec.power(), rec.element(), String(hit[1]))
		var sz: Vector2 = UiDraw.tooltip_size(_tip, rows)
		UiDraw.tooltip_at(_tip, Vector2(mouse.x - sz.x * 0.5, card.position.y - sz.y - 6.0), rows)
	elif _command_at(mouse) >= 0:
		var d: Dictionary = g.commands.data(TrainerCommands.IDS[_command_at(mouse)])
		var rows: Array = [["[%s] %s" % [d["key"], d["name"]], Pal.c(String(d["color"]))]]
		for line: String in UiDraw.wrap(_tip, String(d["desc"]), MoveText.WRAP):
			rows.append(line)
		rows.append(["Cooldown %d s   Stronger with bond" % int(d["cooldown"]), UiDraw.DIM])
		UiDraw.tooltip(_tip, mouse, rows)
	elif strip.member_at(mouse - strip.position) >= 0:
		UiDraw.tooltip(_tip, mouse, ["Click: creature info (I)"])


func _command_at(p: Vector2) -> int:
	for i: int in TrainerCommands.IDS.size():
		if command_rect(i).has_point(p):
			return i
	return -1


func callout(text: String, col: Color) -> void:
	_callout = text
	_callout_col = col
	_callout_t = CALLOUT_TIME


func notice(text: String) -> void:
	_notices.append([text, NOTICE_TIME])
	while _notices.size() > NOTICE_MAX:
		_notices.pop_front()


func caption(text: String) -> void:
	_caption = text
	_caption_t = CAPTION_TIME


func _process(delta: float) -> void:
	var vp: Vector2 = _canvas.size
	card.position = Vector2(roundf((vp.x - card.size.x) * 0.5), vp.y - MARGIN - card.size.y)
	strip.position = Vector2(vp.x - MARGIN - strip.size.x, vp.y - MARGIN - strip.size.y)
	camp_panel.position = ((vp - camp_panel.size) * 0.5).round()
	info_panel.position = Vector2(roundf((vp.x - info_panel.size.x) * 0.5), MARGIN * 3.0)   # clear of the cards below
	_tip.queue_redraw()
	for n: Array in _notices:
		n[1] = float(n[1]) - delta
	_notices = _notices.filter(func(n: Array) -> bool: return float(n[1]) > 0.0)
	_caption_t -= delta
	_victory_t -= delta
	_callout_t -= delta
	_canvas.queue_redraw()


func _draw_canvas() -> void:
	var vp: Vector2 = _canvas.size
	if not tracker_hidden:
		_tracker(Vector2(MARGIN, MARGIN))
	_materials(Vector2(vp.x - MARGIN, MARGIN))
	_commands(command_origin())
	_items(Vector2(MARGIN, vp.y - MARGIN - CMD_ROW - ITEM - 14.0))
	_badge(Vector2(MARGIN, vp.y - MARGIN - CMD_ROW - ITEM - BADGE.y - 26.0))
	for i: int in _notices.size():
		var a: float = clampf(float(_notices[i][1]), 0.0, 1.0)
		UiDraw.text(_canvas, Vector2(0, vp.y * NOTICE_AT + i * LINE), String(_notices[i][0]), Color(UiDraw.TEXT, a), UiDraw.BODY,
			HORIZONTAL_ALIGNMENT_CENTER, vp.x)
	if _victory_t > 0.0:
		_victory_box(vp)
	if _callout_t > 0.0:
		UiDraw.text(_canvas, Vector2(card.position.x, card.position.y - 8.0), "New move: " + _callout,
			Color(_callout_col, clampf(_callout_t * 2.0, 0.0, 1.0)), UiDraw.TITLE, HORIZONTAL_ALIGNMENT_CENTER, card.size.x)
	if _caption_t > 0.0 and _caption != "":
		_caption_box(vp)


func _tracker(at: Vector2) -> void:
	var step: Dictionary = g.guide.current()
	var lines: PackedStringArray = UiDraw.wrap(_canvas, String(step["text"]), TRACKER_W - 16.0, UiDraw.BODY)
	var r := Rect2(at, Vector2(TRACKER_W, 24.0 + lines.size() * LINE))
	UiDraw.box(_canvas, r, Color(UiDraw.PANEL, 0.8))
	UiDraw.text(_canvas, at + Vector2(8, 14), "Trainer prototype", UiDraw.GOLD, UiDraw.BODY)
	UiDraw.text(_canvas, at + Vector2(0, 13), g.guide.progress(), UiDraw.DIM, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_RIGHT, TRACKER_W - 8.0)
	for i: int in lines.size():
		UiDraw.text(_canvas, at + Vector2(14, 28 + i * LINE), lines[i], UiDraw.TEXT, UiDraw.BODY)


func _materials(at: Vector2) -> void:
	var y: float = at.y + 8.0
	var defs: Dictionary = TamerData.rule("materials")
	for id: String in defs:
		var n: int = g.team.count(id)
		if n <= 0:
			continue
		var text: String = "%s  %d" % [defs[id]["name"], n]
		var w: float = UiDraw.text_width(_canvas, text, UiDraw.SMALL)
		_canvas.draw_rect(Rect2(Vector2(at.x - w - 12.0, y - 6.0), Vector2(5, 5)), Pal.c(String(defs[id]["color"])))
		UiDraw.text(_canvas, Vector2(at.x - w, y), text, UiDraw.TEXT, UiDraw.SMALL)
		y += LINE - 2.0


func _items(at: Vector2) -> void:
	var defs: Dictionary = TamerData.rule("items")
	var x: float = at.x
	for id: String in defs:
		var r := Rect2(Vector2(x, at.y), Vector2(ITEM, ITEM))
		UiDraw.box(_canvas, r, UiDraw.PANEL_DEEP)
		var col: Color = Pal.c("rose") if id == "berry" else Pal.c("gold")
		_canvas.draw_circle(r.get_center() + Vector2(0, 1), 6.0, col)
		_canvas.draw_rect(Rect2(r.get_center() + Vector2(-1, -8), Vector2(2, 3)), Pal.c("leaf"))
		UiDraw.text(_canvas, r.end - Vector2(9, 2), str(g.team.items.get(id, 0)), UiDraw.TEXT, UiDraw.SMALL)
		UiDraw.text(_canvas, r.position + Vector2(2, ITEM + 9.0), String(defs[id]["key"]), UiDraw.DIM, UiDraw.SMALL)
		x += ITEM + 6.0


## The mode, always on screen: Exploring (you are the trainer) or Battle (you control your creature).
func _badge(at: Vector2) -> void:
	var on: bool = g.battle.on
	var r := Rect2(at, BADGE)
	UiDraw.box(_canvas, r, Color(UiDraw.PANEL, 0.85), Pal.c("rose") if on else UiDraw.FRAME)
	UiDraw.text(_canvas, at + Vector2(6, 12), "BATTLE" if on else "EXPLORING", Pal.c("rose") if on else UiDraw.TEXT, UiDraw.SMALL)
	var who: String = String(g.field.partner.rec.data()["name"]) if on and g.field.partner != null else "Trainer"
	UiDraw.text(_canvas, at + Vector2(0, 12), "you: " + who.to_lower(), UiDraw.DIM, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_RIGHT, BADGE.x - 6.0)


## A soft dark edge on the screen while a battle is on.
func vignette(on: bool) -> void:
	create_tween().tween_property(_vignette, "modulate:a", 1.0 if on else 0.0, VIGNETTE_TIME)


## "Victory!" and what the fight earned, fading out on its own.
func victory(lines: Array[String]) -> void:
	_victory = lines
	_victory_t = VICTORY_TIME
	Audio.sfx("level_up", -8.0, 1.1)


func _victory_box(vp: Vector2) -> void:
	var a: float = clampf(_victory_t, 0.0, 1.0)
	var w: float = 220.0
	var r := Rect2(Vector2((vp.x - w) * 0.5, vp.y * NOTICE_AT - 70.0), Vector2(w, 30.0 + _victory.size() * LINE))
	UiDraw.box(_canvas, r, Color(UiDraw.PANEL, 0.85 * a), Color(UiDraw.FRAME_LIT, a))
	UiDraw.text(_canvas, r.position + Vector2(0, 18), "Victory!", Color(UiDraw.GOLD, a), UiDraw.TITLE, HORIZONTAL_ALIGNMENT_CENTER, w)
	for i: int in _victory.size():
		UiDraw.text(_canvas, r.position + Vector2(0, 36.0 + i * LINE), _victory[i], Color(UiDraw.TEXT, a), UiDraw.BODY,
			HORIZONTAL_ALIGNMENT_CENTER, w)


func _caption_box(vp: Vector2) -> void:
	var w: float = minf(560.0, vp.x - 40.0)
	var lines: PackedStringArray = UiDraw.wrap(_canvas, _caption, w - 20.0, UiDraw.BODY)
	var h: float = 12.0 + lines.size() * LINE
	var r := Rect2(Vector2((vp.x - w) * 0.5, card.position.y - h - 12.0), Vector2(w, h)).abs()
	var a: float = clampf(_caption_t, 0.0, 1.0)
	_canvas.draw_rect(r, Color(UiDraw.PANEL_DEEP, 0.85 * a))
	_canvas.draw_rect(r, Color(UiDraw.FRAME, a), false, 1.0)
	for i: int in lines.size():
		UiDraw.text(_canvas, Vector2(r.position.x, r.position.y + 15.0 + i * LINE), lines[i], Color(UiDraw.TEXT, a), UiDraw.BODY,
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
