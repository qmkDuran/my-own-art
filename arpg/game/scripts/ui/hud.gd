class_name Hud
extends Control
## The HUD, laid out from the viewport size so it stays whole at any 16:9 or 16:10 window: a bottom-centre cluster
## (life gauge | skill bar with a thin experience bar above it | glory gauge, "current / max" above each gauge),
## points to spend, the objective (under the minimap), the targeted enemy's health and title, verse captions and
## short notices. Drawn by hand, original look.

const SLOT: float = 36.0                # room for a key label above a centred 22 px icon
const GAP: float = 3.0
const MARGIN: float = 6.0
const ORB_R: float = 26.0
const XP_H: float = 2.0                 # 4 px at 1080p
const FLASH_TIME: float = 0.25
const CAPTION_SECONDS: float = 6.0
const NOTICE_SECONDS: float = 3.0

var m: Michael
var objective: PrayerObjective
var _caption: PackedStringArray = []
var _caption_t: float = 0.0
var _notice: String = ""
var _notice_t: float = 0.0
var _flash: Dictionary = {}
var _fade: float = 0.0


func setup(michael: Michael, obj: PrayerObjective) -> void:
	m = michael
	objective = obj
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A quick white-out used for travel: `mid` runs at full white.
func fade_through(mid: Callable) -> void:
	var tw := create_tween()
	tw.tween_property(self, "_fade", 1.0, 0.25)
	tw.tween_callback(mid)
	tw.tween_property(self, "_fade", 0.0, 0.35)


## Light up a skill's slot when it is used.
func flash(id: String) -> void:
	_flash[id] = FLASH_TIME


## A verse caption: "{key}" or plain text.
func caption(s: String) -> void:
	var k: String = s.trim_prefix("{").trim_suffix("}")
	_caption = UiDraw.verse_lines(k, 100) if s.begins_with("{") else PackedStringArray([s])
	_caption_t = CAPTION_SECONDS


func notice(s: String) -> void:
	_notice = s
	_notice_t = NOTICE_SECONDS


func _process(delta: float) -> void:
	_caption_t -= delta
	_notice_t -= delta
	for k: String in _flash:
		_flash[k] = float(_flash[k]) - delta
	queue_redraw()


# ------------------------------------------------------------------ layout
func _vs() -> Vector2:
	return get_viewport_rect().size


## The hotbar slots: LMB, the skill keys, then Dash on Space.
func bar_keys() -> Array:
	return ["LMB"] + GameData.skills["slot_keys"] + ["Space"]


func bar_rect() -> Rect2:
	var n: int = bar_keys().size()
	var w: float = n * (SLOT + GAP) - GAP
	var vs: Vector2 = _vs()
	return Rect2(roundf(vs.x / 2.0 - w / 2.0), vs.y - MARGIN - SLOT, w, SLOT)


func slot_rect(i: int) -> Rect2:
	var bar: Rect2 = bar_rect()
	return Rect2(bar.position.x + i * (SLOT + GAP), bar.position.y, SLOT, SLOT)


func orb_centers() -> Array[Vector2]:
	var bar: Rect2 = bar_rect()
	var y: float = _vs().y - MARGIN - ORB_R
	return [Vector2(bar.position.x - 12.0 - ORB_R, y), Vector2(bar.end.x + 12.0 + ORB_R, y)]


func slot_id(key: String) -> String:
	match key:
		"LMB": return "strike"
		"Space": return "dash"
	return String(m.prog.slots.get(key, ""))


# ------------------------------------------------------------------ drawing
func _draw() -> void:
	if m == null:
		return
	var vs: Vector2 = _vs()
	var oc: Array[Vector2] = orb_centers()
	_orb(oc[0], m.life, m.stats.v("life"), Color("b33831"), Color("e83b3b"))
	_orb(oc[1], m.glory, m.stats.v("glory"), Color("c78b25"), Color("f9c22b"))
	_skill_bar()
	_xp_bar()
	_target_bar()
	var pts: PackedStringArray = []
	if m.prog.skill_points() > 0 or m.prog.attribute_points() > 0:
		pts.append("Points to spend  (K)")
	if m.prog.star_points() > 0:
		pts.append("Stars %d  (P)" % m.prog.star_points())
	UiDraw.text(self, Vector2(8, 16), "Level %d  %s" % [m.prog.level, m.prog.class_title()], UiDraw.GOLD)
	UiDraw.text(self, Vector2(8, 30), "   ".join(pts), Color("fbff86"))
	UiDraw.text(self, Vector2(8, vs.y - 8), "C character   I inventory   K skills   P stars   Alt labels", Color(1, 1, 1, 0.4), UiDraw.SMALL)
	if objective != null:
		var s: String = "Prayers answered %d / %d" % [objective.answered(), objective.points.size()]
		if objective.finished:
			s = "The street is held"
		UiDraw.text(self, Vector2(0, Minimap.AT_Y + 104), s, Color("fbff86"), UiDraw.BODY, HORIZONTAL_ALIGNMENT_RIGHT, vs.x - 8.0)
	if _caption_t > 0.0:
		var a: float = clampf(_caption_t, 0.0, 1.0)
		var top: float = bar_rect().position.y - 18.0 - UiDraw.LINE * _caption.size()
		for i: int in _caption.size():
			UiDraw.text(self, Vector2(0, top + UiDraw.LINE * i), _caption[i], Color(1, 1, 1, a), UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	if _fade > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 1, 1, _fade))
	if _notice_t > 0.0:
		UiDraw.text(self, Vector2(0, vs.y * 0.22), _notice, Color(UiDraw.GOLD, clampf(_notice_t, 0.0, 1.0)), UiDraw.TITLE, HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	_slot_tooltip()


## A round gauge filled from the bottom in whole-pixel rows; "current / max" above it.
func _orb(c: Vector2, cur: float, mx: float, deep: Color, bright: Color) -> void:
	var frac: float = clampf(cur / maxf(1.0, mx), 0.0, 1.0)
	draw_circle(c, ORB_R + 3.0, UiDraw.INK)
	draw_circle(c, ORB_R, Color(0.08, 0.06, 0.1))
	var top: float = c.y + ORB_R - 2.0 * ORB_R * frac
	for y: int in range(int(c.y - ORB_R), int(c.y + ORB_R) + 1):
		if float(y) < top:
			continue
		var dy: float = float(y) - c.y
		var half: float = sqrt(maxf(0.0, ORB_R * ORB_R - dy * dy))
		draw_rect(Rect2(c.x - half, y, half * 2.0, 1.0), bright if dy < -ORB_R * 0.2 else deep)
	draw_arc(c, ORB_R + 1.0, 0.0, TAU, 48, UiDraw.FRAME, 1.0)
	draw_circle(c + Vector2(-9, -10), 3.0, Color(1, 1, 1, 0.25))
	UiDraw.text(self, Vector2(c.x - 50, c.y - ORB_R - 5), "%d / %d" % [roundi(cur), roundi(mx)], Color.WHITE, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, 100.0)


func _skill_bar() -> void:
	var keys: Array = bar_keys()
	for i: int in keys.size():
		var key: String = keys[i]
		var id: String = slot_id(key)
		var r: Rect2 = slot_rect(i)
		if id == "":
			UiDraw.box(self, r, Color(0.06, 0.05, 0.09, 0.8), Color(0.3, 0.28, 0.24))
			UiDraw.text(self, r.position + Vector2(3, 8), key, Color(0.6, 0.6, 0.6), UiDraw.SMALL)
			continue
		var ready: bool = id == "dash" or m.skills.learned(id)
		var lit: bool = float(_flash.get(id, 0.0)) > 0.0 or (id == "radiance" and m.skills.radiance_on)
		UiDraw.box(self, r, Color(0.25, 0.2, 0.06, 0.95) if float(_flash.get(id, 0.0)) > 0.0 else Color(0.06, 0.05, 0.09, 0.95),
			Color("fbff86") if lit else UiDraw.FRAME)
		SkillIcons.draw_icon(self, id, r.get_center() + Vector2(0, 2), Color.WHITE if ready else Color(0.4, 0.4, 0.45))
		var cd: float = m.dodge_ready() if id == "dash" else m.skills.remaining(id)
		var total: float = m.dash_cooldown() if id == "dash" else m.stats.cooldown(float(GameData.skill(id)["cooldown"]))
		if cd > 0.0 and total > 0.0:
			_sweep(r, clampf(cd / total, 0.0, 1.0))
			UiDraw.text(self, Vector2(r.position.x, r.end.y - 3), "%.1f" % cd, Color.WHITE, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		elif id != "dash" and ready and m.glory < float(GameData.skill(id)["cost"]):
			draw_rect(r.grow(-1.0), Color(0.1, 0.1, 0.4, 0.5))
		UiDraw.text(self, r.position + Vector2(3, 8), key, Color("dcd3c0"), UiDraw.SMALL)


## A clockwise cooldown sweep over the slot, starting at 12 o'clock, clipped to the slot.
func _sweep(r: Rect2, frac: float) -> void:
	var c: Vector2 = r.get_center()
	var pts := PackedVector2Array([c])
	var steps: int = 24
	for k: int in steps + 1:
		var a: float = -PI / 2.0 + TAU * (1.0 - frac) + TAU * frac * k / steps
		var d := Vector2(cos(a), sin(a))
		var t: float = minf((r.size.x / 2.0) / maxf(absf(d.x), 0.001), (r.size.y / 2.0) / maxf(absf(d.y), 0.001))
		pts.append(c + d * t)
	draw_colored_polygon(pts, Color(0, 0, 0, 0.6))


func _xp_bar() -> void:
	var bar: Rect2 = bar_rect()
	var r := Rect2(bar.position.x, bar.position.y - XP_H - 3.0, bar.size.x, XP_H)
	draw_rect(r.grow(1.0), UiDraw.INK)
	draw_rect(Rect2(r.position, Vector2(r.size.x * m.prog.xp / Progression.xp_for(m.prog.level), r.size.y)), Color("8fd3ff"))


## Health, numbers and full title (rank and champion modifiers) of the demon under the cursor.
func _target_bar() -> void:
	var mouse: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	var g := get_tree().current_scene as Game
	if g != null:
		mouse = g.mouse_world()
	var best: Demon = null
	for n: Node in get_tree().get_nodes_in_group("demons"):
		var d := n as Demon
		if d != null and d.global_position.distance_to(mouse + Vector2(0, 24)) < 34.0:
			best = d
	if best == null:
		return
	var vs: Vector2 = _vs()
	var r := Rect2(roundf(vs.x / 2.0 - 100.0), 30, 200, 8)
	draw_rect(r.grow(1.0), UiDraw.INK)
	draw_rect(Rect2(r.position, Vector2(r.size.x * best.hp / best.max_hp, r.size.y)), Color("b33831"))
	if best.barrier > 0.0:
		draw_rect(Rect2(r.position, Vector2(r.size.x * minf(1.0, best.barrier / best.max_hp), 2)), Color("c7dcd0"))
	var title: String = best.display_name() + ("  (Champion)" if best.rank == "champion" else "")
	UiDraw.text(self, Vector2(0, 24), title, Color("f57d4a") if best.rank != "" else Color.WHITE, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	UiDraw.text(self, Vector2(0, 47), "%d / %d" % [roundi(best.hp), roundi(best.max_hp)], Color.WHITE, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, vs.x)


## Hovering a hotbar slot shows the skill's numbers.
func _slot_tooltip() -> void:
	var mp: Vector2 = get_viewport().get_mouse_position()
	var keys: Array = bar_keys()
	for i: int in keys.size():
		if slot_rect(i).has_point(mp):
			var id: String = slot_id(keys[i])
			if id != "":
				UiDraw.tooltip(self, mp - Vector2(0, 120), SkillInfo.lines(m, id), UiDraw.GOLD)
