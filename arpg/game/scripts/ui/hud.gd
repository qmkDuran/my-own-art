class_name Hud
extends Control
## Life (left) and glory (right) gauges, the skill bar with cooldowns, the experience bar, points to spend,
## the objective, the targeted enemy's health, verse captions and short notices. Drawn by hand, original look.

const ORB_R: float = 34.0
const LIFE_POS := Vector2(56, 486)
const GLORY_POS := Vector2(904, 486)
const SLOT: float = 34.0
const BAR_Y: float = 488.0
const CAPTION_Y: float = 452.0
const CAPTION_SECONDS: float = 6.0
const NOTICE_SECONDS: float = 3.0

var m: Michael
var objective: PrayerObjective
var _caption: PackedStringArray = []
var _caption_t: float = 0.0
var _notice: String = ""
var _notice_t: float = 0.0


func setup(michael: Michael, obj: PrayerObjective) -> void:
	m = michael
	objective = obj
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A verse caption: "{key}" or plain text.
func caption(s: String) -> void:
	var k: String = s.trim_prefix("{").trim_suffix("}")
	_caption = UiDraw.verse_lines(k, 90) if s.begins_with("{") else PackedStringArray([s])
	_caption_t = CAPTION_SECONDS


func notice(s: String) -> void:
	_notice = s
	_notice_t = NOTICE_SECONDS


func _process(delta: float) -> void:
	_caption_t -= delta
	_notice_t -= delta
	queue_redraw()


func _draw() -> void:
	if m == null:
		return
	_orb(LIFE_POS, m.life / m.stats.v("life"), Color("b33831"), Color("e83b3b"), "%d" % roundi(m.life))
	_orb(GLORY_POS, m.glory / m.stats.v("glory"), Color("c78b25"), Color("f9c22b"), "%d" % roundi(m.glory))
	_skill_bar()
	_xp_bar()
	_target_bar()
	var pts: PackedStringArray = []
	if m.prog.skill_points() > 0:
		pts.append("Skill points %d  (K)" % m.prog.skill_points())
	if m.prog.star_points() > 0:
		pts.append("Stars %d  (P)" % m.prog.star_points())
	UiDraw.text(self, Vector2(8, 18), "Level %d" % m.prog.level, UiDraw.GOLD)
	UiDraw.text(self, Vector2(8, 34), "   ".join(pts), Color("fbff86"))
	if objective != null:
		var s: String = "Prayers answered %d / %d" % [objective.answered(), objective.points.size()]
		if objective.finished:
			s = "The street is held"
		UiDraw.text(self, Vector2(0, 18), s, Color("fbff86"), 16, HORIZONTAL_ALIGNMENT_RIGHT, 952.0)
	if _caption_t > 0.0:
		var a: float = clampf(_caption_t, 0.0, 1.0)
		for i: int in _caption.size():
			UiDraw.text(self, Vector2(0, CAPTION_Y - 14.0 * (_caption.size() - 1 - i)), _caption[i],
				Color(1, 1, 1, a), 16, HORIZONTAL_ALIGNMENT_CENTER, 960.0)
	if _notice_t > 0.0:
		UiDraw.text(self, Vector2(0, 120), _notice, Color(UiDraw.GOLD, clampf(_notice_t, 0.0, 1.0)), 32, HORIZONTAL_ALIGNMENT_CENTER, 960.0)


## A round gauge filled from the bottom in whole-pixel rows.
func _orb(c: Vector2, frac: float, deep: Color, bright: Color, label: String) -> void:
	draw_circle(c, ORB_R + 3.0, UiDraw.INK)
	draw_circle(c, ORB_R, Color(0.08, 0.06, 0.1))
	var top: float = c.y + ORB_R - 2.0 * ORB_R * clampf(frac, 0.0, 1.0)
	for y: int in range(int(c.y - ORB_R), int(c.y + ORB_R) + 1):
		if float(y) < top:
			continue
		var dy: float = float(y) - c.y
		var half: float = sqrt(maxf(0.0, ORB_R * ORB_R - dy * dy))
		var col: Color = bright if dy < -ORB_R * 0.2 else deep
		draw_rect(Rect2(c.x - half, y, half * 2.0, 1.0), col)
	draw_arc(c, ORB_R + 1.0, 0.0, TAU, 48, UiDraw.FRAME, 1.0)
	draw_circle(c + Vector2(-12, -14), 4.0, Color(1, 1, 1, 0.25))
	UiDraw.text(self, Vector2(c.x - 40, c.y + 6), label, Color.WHITE, 16, HORIZONTAL_ALIGNMENT_CENTER, 80.0)


func _skill_bar() -> void:
	var ids: Array = GameData.skills["slots"]
	var x0: float = 480.0 - (SLOT + 4.0) * ids.size() / 2.0
	for i: int in ids.size():
		var id: String = ids[i]
		var r := Rect2(x0 + i * (SLOT + 4.0), BAR_Y, SLOT, SLOT)
		var learned: bool = m.skills.learned(id)
		UiDraw.box(self, r, Color(0.06, 0.05, 0.09, 0.95), UiDraw.GOLD if (id == "radiance" and m.skills.radiance_on) else UiDraw.FRAME)
		SkillIcons.draw_icon(self, id, r.get_center(), Color.WHITE if learned else Color(0.4, 0.4, 0.45))
		var cd: float = m.skills.remaining(id)
		var total: float = m.stats.cooldown(float(GameData.skill(id)["cooldown"]))
		if learned and cd > 0.0 and total > 0.0:
			var h: float = SLOT * cd / total
			draw_rect(Rect2(r.position.x, r.end.y - h, SLOT, h), Color(0, 0, 0, 0.6))
		elif learned and m.glory < float(GameData.skill(id)["cost"]):
			draw_rect(r, Color(0.1, 0.1, 0.4, 0.5))
		UiDraw.text(self, r.position + Vector2(2, 12), String(GameData.skill(id)["key"]).get_slice(" ", 0), Color("dcd3c0"))


func _xp_bar() -> void:
	var r := Rect2(110, 530, 740, 4)
	draw_rect(r.grow(1.0), UiDraw.INK)
	draw_rect(Rect2(r.position, Vector2(r.size.x * m.prog.xp / Progression.xp_for(m.prog.level), r.size.y)), Color("8fd3ff"))


## Health of the demon nearest the mouse (within reach of the cursor).
func _target_bar() -> void:
	var mouse: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	var best: Demon = null
	for n: Node in get_tree().get_nodes_in_group("demons"):
		var d := n as Demon
		if d != null and d.global_position.distance_to(mouse + Vector2(0, 24)) < 34.0:
			best = d
	if best == null:
		return
	var r := Rect2(380, 40, 200, 8)
	draw_rect(r.grow(1.0), UiDraw.INK)
	draw_rect(Rect2(r.position, Vector2(r.size.x * best.hp / best.max_hp, r.size.y)), Color("b33831"))
	var title: String = best.display_name() + ("  (Champion)" if best.rank == "champion" else "")
	UiDraw.text(self, Vector2(0, 36), title, Color("f57d4a") if best.rank != "" else Color.WHITE, 16, HORIZONTAL_ALIGNMENT_CENTER, 960.0)
