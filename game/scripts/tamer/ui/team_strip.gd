class_name TeamStrip
extends Control
## Your team on keys 1-3: a portrait per member with its life and bond, the one that is out framed in gold, a
## knocked-out one greyed with its recovery time, and empty slots waiting to be filled by befriending. Click one for
## its info panel.

const SLOT := Vector2(44, 44)
const GAP: float = 6.0
const BAR_H: float = 3.0
const HEART: float = 2.0

var g: TamerGame


func setup(game: TamerGame) -> void:
	g = game
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)
	tooltip_text = ""
	var n: int = int(TamerData.rule("team_max"))
	size = Vector2(n * SLOT.x + (n - 1) * GAP, SLOT.y + 22.0)


## Clicking a member opens its info panel.
func _on_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var i: int = member_at(mb.position)
	if i >= 0:
		g.hud.info_panel.toggle(g.team.members[i])
		accept_event()


func member_at(p: Vector2) -> int:
	for i: int in g.team.members.size():
		if Rect2(Vector2(i * (SLOT.x + GAP), 0), SLOT).has_point(p):
			return i
	return -1


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for i: int in int(TamerData.rule("team_max")):
		var r := Rect2(Vector2(i * (SLOT.x + GAP), 0), SLOT)
		if i >= g.team.members.size():
			UiDraw.box(self, r, Color(UiDraw.PANEL, 0.5), UiDraw.LOCKED)
			UiDraw.text(self, r.position + Vector2(0, r.size.y * 0.5 + 3.0), "empty", UiDraw.LOCKED, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		else:
			_member(g.team.members[i], r, i == g.team.active)
		UiDraw.text(self, r.position + Vector2(2, 9), str(i + 1), UiDraw.GOLD, UiDraw.SMALL)


func _member(rec: CreatureRecord, r: Rect2, active: bool) -> void:
	CreaturePortrait.draw_in(self, r, rec)
	if active:
		draw_rect(r.grow(1.0), UiDraw.FRAME_LIT, false, 2.0)
	var bar := Rect2(r.position + Vector2(0, r.size.y + 4.0), Vector2(r.size.x, BAR_H))
	draw_rect(bar.grow(1.0), UiDraw.INK)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * rec.life_frac(), BAR_H)), Pal.c("leaf_lt") if rec.life_frac() > 0.3 else Pal.c("rose"))
	var bond := Rect2(bar.position + Vector2(0, BAR_H + 3.0), Vector2(r.size.x, BAR_H - 1.0))
	draw_rect(bond.grow(1.0), UiDraw.INK)
	draw_rect(Rect2(bond.position, Vector2(bond.size.x * rec.bond_frac(), bond.size.y)), Pal.c("rose"))
	if rec.bond_move_ready():
		draw_circle(r.end - Vector2(5, 5), HEART + 1.0, UiDraw.INK)
		draw_circle(r.end - Vector2(5, 5), HEART, Pal.c("rose"))
	if rec.knocked_out():
		draw_rect(r, Color(0, 0, 0, 0.45))
		UiDraw.text(self, r.position + Vector2(0, r.size.y * 0.5 + 4.0), "%ds" % ceili(rec.ko_left), Pal.c("rose"), UiDraw.BODY,
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
