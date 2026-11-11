class_name HudButtons
extends Control
## Clickable shortcuts beside the life orb, each with its key: Inventory (I), Skills (K), Passives (P), Quests (J),
## Map (M). Skills and Passives pulse when there are points to spend.

const BTN := Vector2(40, 18)
const PAD: float = 3.0              ## text keeps this far from the border (the UI check measures it)
const GAP: float = 2.0
const ITEMS: Array = [["character", "Char", "C"], ["inventory", "Bag", "I"], ["skills", "Skills", "K"], ["passives", "Pass.", "P"], ["quests", "Quests", "J"],
	["map", "Map", "M"]]

var g: Game


## The buttons in a row ending at `right_bottom` (their bottom-right corner), left of the life orb.
static func rects(right_bottom: Vector2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var x0: float = right_bottom.x - ITEMS.size() * (BTN.x + GAP)
	for i: int in ITEMS.size():
		out.append(Rect2(x0 + i * (BTN.x + GAP), right_bottom.y - BTN.y - 10.0, BTN.x, BTN.y + 10.0))
	return out


## Does every label fit inside its button with PAD to spare? (For the UI check.)
static func labels_fit(ci: CanvasItem) -> bool:
	for it: Array in ITEMS:
		if UiDraw.text_width(ci, String(it[1]), UiDraw.SMALL) > BTN.x - PAD * 2.0:
			return false
	return true


func setup(game: Game) -> void:
	g = game
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _area() -> Array[Rect2]:
	return Hud.layout(get_viewport_rect().size)["buttons"]


func _pulsing(id: String) -> bool:
	var p: Progression = g.player.prog
	if id == "passives":
		return p.passive_points() > 0
	if id == "skills":
		return p.skills.keys().any(func(s: String) -> bool: return p.can_specialise(s) or (p.is_specialised(s) and p.spec_points(s) > 0))
	return false


func _draw() -> void:
	var rs: Array[Rect2] = _area()
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 220.0)
	for i: int in ITEMS.size():
		var r: Rect2 = rs[i]
		var hot: bool = _pulsing(String(ITEMS[i][0]))
		UiDraw.box(self, r, Color(0.14, 0.1, 0.08).lerp(Color(0.4, 0.26, 0.08), pulse if hot else 0.0), UiDraw.FRAME_LIT if hot else UiDraw.FRAME)
		UiDraw.text(self, r.position + Vector2(0, 11), String(ITEMS[i][1]), UiDraw.TEXT, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		UiDraw.text(self, r.position + Vector2(0, 24), String(ITEMS[i][2]), UiDraw.GOLD, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


## Clicks on a button open its panel (the Hud itself ignores the mouse, so this checks the press directly).
func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or get_tree().paused:
		return
	var rs: Array[Rect2] = _area()
	for i: int in ITEMS.size():
		if rs[i].has_point(mb.position):
			get_viewport().set_input_as_handled()
			var id: String = String(ITEMS[i][0])
			if id == "map":
				g.ui.minimap.toggle_large()
			else:
				g.ui.open(g.ui.get(id))
			return
