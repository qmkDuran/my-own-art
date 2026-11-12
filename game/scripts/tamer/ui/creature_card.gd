class_name CreatureCard
extends Control
## The active creature at the bottom of the screen: its portrait, name, element and level, life, the bond meter
## (with the mark where the bond move unlocks), and its moves on Q W E R plus the bond move on T, each with its
## cooldown. While it is knocked out the card says how long until it is back.

const PORTRAIT: float = 50.0
const SLOT: float = 26.0
const SLOT_GAP: float = 6.0
const BAR_H: float = 6.0
const BOND_H: float = 3.0
const GAP: float = 6.0
const SIZE := Vector2(300, 74)

var g: TamerGame


func setup(game: TamerGame) -> void:
	g = game
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = SIZE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var rec: CreatureRecord = g.team.current()
	UiDraw.box(self, Rect2(Vector2.ZERO, size), Color(UiDraw.PANEL, 0.85))
	if rec == null:
		UiDraw.text(self, Vector2(0, size.y * 0.5 + 4.0), "No creature yet", UiDraw.DIM, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, size.x)
		return
	var pr := Rect2(Vector2(GAP, GAP), Vector2(PORTRAIT, PORTRAIT))
	CreaturePortrait.draw_in(self, pr, rec)
	var x: float = pr.end.x + GAP
	var w: float = size.x - x - GAP
	_title(rec, Vector2(x, GAP + 9.0), w)
	_bars(rec, Vector2(x, GAP + 14.0), w)
	_moves(rec, Vector2(x, GAP + 27.0))
	if rec.knocked_out():
		draw_rect(Rect2(pr.position, pr.size), Color(0, 0, 0, 0.5))
		UiDraw.text(self, pr.position + Vector2(0, pr.size.y * 0.5 + 4.0), "%ds" % ceili(rec.ko_left), Pal.c("rose"), UiDraw.BODY,
			HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)


func _title(rec: CreatureRecord, at: Vector2, w: float) -> void:
	var el: String = rec.element()
	UiDraw.text(self, at, rec.display_name(), Pal.c("gold") if rec.shiny else UiDraw.TEXT, UiDraw.BODY)
	var tag: String = "%s  Lv %d" % [String(TamerData.element(el)["name"]).to_upper(), rec.level]
	UiDraw.text(self, at + Vector2(0, -1), tag, TamerData.color(el, "light"), UiDraw.SMALL, HORIZONTAL_ALIGNMENT_RIGHT, w)


func _bars(rec: CreatureRecord, at: Vector2, w: float) -> void:
	draw_rect(Rect2(at - Vector2.ONE, Vector2(w + 2.0, BAR_H + 2.0)), UiDraw.INK)
	draw_rect(Rect2(at, Vector2(w * rec.life_frac(), BAR_H)), Pal.c("leaf_lt") if rec.life_frac() > 0.3 else Pal.c("rose"))
	var bt: Vector2 = at + Vector2(0, BAR_H + 3.0)
	draw_rect(Rect2(bt - Vector2.ONE, Vector2(w + 2.0, BOND_H + 2.0)), UiDraw.INK)
	draw_rect(Rect2(bt, Vector2(w * rec.bond_frac(), BOND_H)), Pal.c("rose"))
	var mark: float = w * float(TamerData.rule("bond.unlock")) / float(TamerData.rule("bond.max"))
	draw_rect(Rect2(bt + Vector2(mark, -2), Vector2(1, BOND_H + 4.0)), Pal.c("sun") if rec.bond_move_ready() else UiDraw.DIM)


## The move under a point in the card's own coordinates ([id, key] or empty), for the tooltip.
func move_at(p: Vector2) -> Array:
	var rec: CreatureRecord = g.team.current()
	if rec == null:
		return []
	var ids: Array = rec.moves().duplicate()
	ids.append(rec.bond_move())
	var keys: Array[String] = TamerKeys.MOVE_LABELS.duplicate()
	keys.append("T")
	for i: int in ids.size():
		if _slot_rect(i).has_point(p):
			return [String(ids[i]), keys[i]]
	return []


func _slot_rect(i: int) -> Rect2:
	var at := Vector2(GAP + PORTRAIT + GAP, GAP + 27.0)
	var x: float = i * (SLOT + SLOT_GAP) + (SLOT_GAP if i >= TamerKeys.MOVE_LABELS.size() else 0.0)
	return Rect2(at + Vector2(x, 0), Vector2(SLOT, SLOT))


func _moves(rec: CreatureRecord, at: Vector2) -> void:
	var c: Creature = g.field.partner if g.field.partner != null and g.field.partner.rec == rec else null
	var kit: Array = rec.moves()
	for i: int in kit.size():
		_slot(c, String(kit[i]), rec.element(), TamerKeys.MOVE_LABELS[i], at + Vector2(i * (SLOT + SLOT_GAP), 0), false)
	var bond_at: Vector2 = at + Vector2(kit.size() * (SLOT + SLOT_GAP) + SLOT_GAP, 0)
	_slot(c, rec.bond_move(), rec.element(), "T", bond_at, not rec.bond_move_ready())


func _slot(c: Creature, id: String, el: String, key: String, at: Vector2, locked: bool) -> void:
	var frac: float = c.cooldown_frac(id) if c != null else 0.0
	var left: float = float(c.cooldowns.get(id, 0.0)) if c != null else 0.0
	MoveIcon.draw_slot(self, Rect2(at, Vector2(SLOT, SLOT)), id, el, key, frac, left, locked)
