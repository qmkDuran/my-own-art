class_name TamerHud
extends CanvasLayer
## The prototype's screen: the tracker (what to try next) top left, materials top right, notices top centre, the
## story caption above the cards; bottom left the trainer's life orb, the two items and the "controlling" badge;
## bottom centre the active creature's card; bottom right the team strip; the camp panel when resting. Laid out
## from the viewport size every frame (no fixed coordinates).

const LAYER: int = 10
const MARGIN: float = 10.0
const ORB: float = 58.0
const ITEM: float = 26.0
const TRACKER_W: float = 300.0
const NOTICE_TIME: float = 4.0
const NOTICE_MAX: int = 3
const NOTICE_AT: float = 0.24           ## share of the screen height where notices start (clear of the tracker)
const CAPTION_TIME: float = 6.0
const LINE: float = 13.0
const BADGE := Vector2(150, 18)

var g: TamerGame
var orb := HudOrb.new()
var card := CreatureCard.new()
var strip := TeamStrip.new()
var camp_panel := CampPanel.new()
var tracker_hidden: bool = false
var _canvas := Control.new()
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
	orb.setup(Pal.c("blood"), Pal.c("rose"), Pal.c("skin_lt"))
	add_child(orb)
	card.setup(g)
	add_child(card)
	strip.setup(g)
	add_child(strip)
	camp_panel.setup(g)
	add_child(camp_panel)


func notice(text: String) -> void:
	_notices.append([text, NOTICE_TIME])
	while _notices.size() > NOTICE_MAX:
		_notices.pop_front()


func caption(text: String) -> void:
	_caption = text
	_caption_t = CAPTION_TIME


func _process(delta: float) -> void:
	var vp: Vector2 = _canvas.size
	orb.place(Rect2(Vector2(MARGIN, vp.y - MARGIN - ORB), Vector2(ORB, ORB)))
	orb.set_value(g.trainer.life / g.trainer.max_life, delta)
	orb.label = "%d" % ceili(g.trainer.life)
	card.position = Vector2(roundf((vp.x - card.size.x) * 0.5), vp.y - MARGIN - card.size.y)
	strip.position = Vector2(vp.x - MARGIN - strip.size.x, vp.y - MARGIN - strip.size.y)
	camp_panel.position = ((vp - camp_panel.size) * 0.5).round()
	for n: Array in _notices:
		n[1] = float(n[1]) - delta
	_notices = _notices.filter(func(n: Array) -> bool: return float(n[1]) > 0.0)
	_caption_t -= delta
	_canvas.queue_redraw()


func _draw_canvas() -> void:
	var vp: Vector2 = _canvas.size
	if not tracker_hidden:
		_tracker(Vector2(MARGIN, MARGIN))
	_materials(Vector2(vp.x - MARGIN, MARGIN))
	_items(Vector2(MARGIN + ORB + 8.0, vp.y - MARGIN - ITEM - 10.0))
	_badge(Vector2(MARGIN, vp.y - MARGIN - ORB - BADGE.y - 6.0))
	for i: int in _notices.size():
		var a: float = clampf(float(_notices[i][1]), 0.0, 1.0)
		UiDraw.text(_canvas, Vector2(0, vp.y * NOTICE_AT + i * LINE), String(_notices[i][0]), Color(UiDraw.TEXT, a), UiDraw.BODY,
			HORIZONTAL_ALIGNMENT_CENTER, vp.x)
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


## Who you are steering, always on screen, gold while it is your creature.
func _badge(at: Vector2) -> void:
	var on: bool = g.control.on
	var who: String = String(g.field.partner.rec.data()["name"]) if on and g.field.partner != null else "Trainer"
	var r := Rect2(at, BADGE)
	UiDraw.box(_canvas, r, Color(UiDraw.PANEL, 0.85), UiDraw.FRAME_LIT if on else UiDraw.FRAME)
	UiDraw.text(_canvas, at + Vector2(6, 12), "CONTROLLING", UiDraw.DIM, UiDraw.SMALL)
	UiDraw.text(_canvas, at + Vector2(0, 12), who.to_upper(), Pal.c("gold") if on else UiDraw.TEXT, UiDraw.SMALL,
		HORIZONTAL_ALIGNMENT_RIGHT, BADGE.x - 6.0)
	UiDraw.text(_canvas, at + Vector2(0, -3), "hold SHIFT: steer your creature", UiDraw.DIM, UiDraw.SMALL)


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
