class_name Hud
extends Control
## The always-on HUD, laid out from the viewport size (layout() is pure so the UI check can test every 16:9 and
## 16:10 size): life and Oil orbs, the hotbar (LMB RMB Q W E R | Space 1) with cooldown sweeps, the Light gauge
## above it, experience below, the objective tracker top-left, boss/target bar top-centre. Messages (captions,
## dialogue, notes) are drawn by HudMessages.

const SLOT: float = 28.0
const GAP: float = 2.0
const SEP: float = 8.0
const ORB: float = 54.0
const ORB_GAP: float = 10.0
const MARGIN: float = 6.0
const XP_H: float = 4.0
const GAUGE_H: float = 7.0
const GAUGE_LABEL: float = 12.0
const ICON: float = 24.0
const SLOT_KEYS: Array[String] = ["lmb", "rmb", "q", "w", "e", "r", "dash", "tonic"]
const KEY_LABELS: Array[String] = ["LMB", "RMB", "Q", "W", "E", "R", "SPC", "1"]
const TRACKER := Rect2(8, 8, 214, 56)
const BAR_W: float = 300.0
const BAR_H: float = 12.0
const ORB_SEGMENTS: int = 40

var g: Game
var messages: HudMessages
var boss: Enemy
var tracker_hidden: bool = false
var _skills_tex: Texture2D
var _t: float = 0.0


func setup(game: Game) -> void:
	g = game
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skills_tex = PropSprite.tex("res://art/ui/skills.png")
	messages = HudMessages.new()
	add_child(messages)
	messages.setup(self)


static func layout(vs: Vector2) -> Dictionary:
	var n: int = SLOT_KEYS.size()
	var bar_w: float = n * SLOT + (n - 1) * GAP + SEP
	var total: float = ORB * 2.0 + ORB_GAP * 2.0 + bar_w
	var x0: float = roundf((vs.x - total) / 2.0)
	var bottom: float = vs.y - MARGIN
	var bx: float = x0 + ORB + ORB_GAP
	var slots: Array[Rect2] = []
	for i: int in n:
		slots.append(Rect2(bx + i * (SLOT + GAP) + (SEP if i >= 6 else 0.0), bottom - XP_H - 4.0 - SLOT, SLOT, SLOT))
	var gauge := Rect2(bx, slots[0].position.y - 4.0 - GAUGE_H, bar_w, GAUGE_H)
	return {
		"life": Rect2(x0, bottom - ORB, ORB, ORB), "oil": Rect2(x0 + total - ORB, bottom - ORB, ORB, ORB),
		"slots": slots, "xp": Rect2(bx, bottom - XP_H, bar_w, XP_H), "gauge": gauge,
		"gauge_label": Rect2(bx, gauge.position.y - GAUGE_LABEL, bar_w, GAUGE_LABEL),
		"cluster": Rect2(x0, gauge.position.y - GAUGE_LABEL, total, bottom - gauge.position.y + GAUGE_LABEL),
		"tracker": TRACKER, "minimap": Minimap.rect_for(vs),
		"bar": Rect2(roundf((vs.x - BAR_W) / 2.0), 22.0, BAR_W, BAR_H),
	}


func notice(s: String) -> void:
	messages.notice(s)


func caption(s: String) -> void:
	messages.caption(s)


func show_dialogue(lines: Array) -> void:
	messages.dialogue(lines)


func show_note(title: String, lines: Array) -> void:
	messages.note(title, lines)


func track_boss(e: Enemy) -> void:
	boss = e


func slot_rect(i: int) -> Rect2:
	return (layout(get_viewport_rect().size)["slots"] as Array)[i]


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	_hover_tips()


func _draw() -> void:
	var L: Dictionary = layout(get_viewport_rect().size)
	var p: Player = g.player
	_orb(L["life"], p.life / p.stats.max_life(), Pal.c("blood"), Pal.c("rose"), "%d/%d" % [ceili(p.life), roundi(p.stats.max_life())])
	_orb(L["oil"], p.oil / p.stats.max_oil(), Pal.c("ember"), Pal.c("amber"), "%d/%d" % [floori(p.oil), roundi(p.stats.max_oil())])
	_gauge(L["gauge"], L["gauge_label"])
	for i: int in SLOT_KEYS.size():
		_slot(L["slots"][i], i)
	_xp(L["xp"])
	if not tracker_hidden:
		_tracker()
	_top_bar(L["bar"])


# ------------------------------------------------------------------ pieces
func _orb(r: Rect2, frac: float, deep: Color, bright: Color, label: String) -> void:
	var c: Vector2 = r.get_center()
	var rad: float = r.size.x * 0.5
	draw_circle(c, rad + 2.0, UiDraw.INK)
	draw_circle(c, rad, Color(0.05, 0.04, 0.07))
	_orb_fill(c, rad - 1.0, clampf(frac, 0.0, 1.0), deep)
	draw_circle(c + Vector2(0, rad * 0.25), rad * 0.45 * clampf(frac * 1.4, 0.0, 1.0), Color(bright, 0.45))
	draw_arc(c, rad - 3.0, PI * 1.15, PI * 1.55, 10, Color(1, 1, 1, 0.35), 2.0)
	draw_arc(c, rad, 0.0, TAU, 48, UiDraw.FRAME, 2.0)
	draw_arc(c, rad + 1.0, PI * 1.2, PI * 1.8, 16, UiDraw.FRAME_LIT, 1.0)
	UiDraw.text(self, Vector2(r.position.x, c.y + 4.0), label, UiDraw.TEXT, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


## The liquid: the part of the circle below a gently waving surface line.
func _orb_fill(c: Vector2, rad: float, frac: float, col: Color) -> void:
	if frac <= 0.01:
		return
	if frac >= 0.99:
		draw_circle(c, rad, col)
		return
	var level: float = c.y + rad - 2.0 * rad * frac
	var half: float = sqrt(maxf(0.0, rad * rad - pow(level - c.y, 2.0)))
	var a0: float = atan2(level - c.y, half)
	var a1: float = PI - a0
	var pts := PackedVector2Array()
	for i: int in ORB_SEGMENTS + 1:
		var a: float = lerpf(a0, a1, float(i) / ORB_SEGMENTS)
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	for i: int in range(ORB_SEGMENTS - 1, 0, -1):
		var u: float = float(i) / ORB_SEGMENTS
		var x: float = lerpf(c.x + half, c.x - half, u)
		pts.append(Vector2(x, level + sin(_t * 3.0 + x * 0.2) * sin(u * PI) * 0.8 * minf(1.0, half / 8.0)))
	draw_colored_polygon(pts, col)


func _gauge(r: Rect2, label_r: Rect2) -> void:
	var lt: LanternLight = g.player.light
	var L: Dictionary = GameData.light
	var k: float = (lt.value - float(L["min"])) / (float(L["max"]) - float(L["min"]))
	draw_rect(r.grow(1.0), UiDraw.INK)
	draw_rect(r, Color(0.08, 0.06, 0.06))
	var col: Color = Pal.c("gold") if lt.state() == "blazing" else (Pal.c("rose") if lt.state() == "guttering" else Pal.c("amber"))
	draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), col)
	draw_rect(Rect2(r.position, Vector2(r.size.x * k, 2)), Color(1, 1, 1, 0.3))
	for mark: String in ["calm_low", "calm_high", "blazing_at"]:
		var x: float = r.position.x + r.size.x * (float(L[mark]) - float(L["min"])) / (float(L["max"]) - float(L["min"]))
		draw_line(Vector2(x, r.position.y - 1), Vector2(x, r.end.y + 1), UiDraw.FRAME_LIT if mark == "blazing_at" else UiDraw.FRAME)
	draw_rect(r, UiDraw.FRAME, false, 1.0)
	var word: String = {"blazing": "Blazing", "guttering": "Guttering", "calm": ""}[lt.state()]
	if lt.thrown:
		word = "Lantern thrown"
	if word != "":
		UiDraw.text(self, label_r.position + Vector2(0, 9), word, col, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, label_r.size.x)


func _slot(r: Rect2, i: int) -> void:
	UiDraw.box(self, r, Color(0.07, 0.06, 0.1, 0.95))
	var key: String = SLOT_KEYS[i]
	var id: String = _slot_skill(key)
	var cd := Vector2.ZERO
	var dim: bool = false
	if id != "":
		var icon: int = int(GameData.skill(id)["icon"]) if GameData.skills.has(id) else 7
		draw_texture_rect_region(_skills_tex, Rect2(r.get_center() - Vector2(ICON, ICON) * 0.5, Vector2(ICON, ICON)),
			Rect2(icon * ICON, 0, ICON, ICON))
		cd = _cooldown(key, id)
		dim = _unaffordable(key, id)
	if dim:
		draw_rect(r.grow(-1.0), Color(0.1, 0.15, 0.4, 0.5))
	if cd.x > 0.0 and cd.y > 0.0:
		_sweep(r, cd.x / cd.y)
		UiDraw.text(self, r.position + Vector2(0, 18), "%.1f" % cd.x, UiDraw.TEXT, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	UiDraw.text(self, r.position + Vector2(2, 8), KEY_LABELS[i], UiDraw.GOLD, UiDraw.SMALL)
	if key == "tonic":
		UiDraw.text(self, r.position + Vector2(0, r.size.y - 2), str(g.player.tonics), UiDraw.TEXT, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 2)


func _slot_skill(key: String) -> String:
	if key == "dash":
		return "dash"
	if key == "tonic":
		return "tonic"
	return String(g.player.prog.slots.get(key, ""))


func _cooldown(key: String, id: String) -> Vector2:
	if key == "dash":
		return g.player.dash_cooldown()
	if key == "tonic":
		return Vector2.ZERO
	return g.player.skills.cooldown_left(id)


func _unaffordable(key: String, id: String) -> bool:
	if key == "tonic":
		return g.player.tonics == 0
	return key != "dash" and g.player.skills.block(id) == "oil"


## Cooldown shade: a dark curtain over the slot that lifts as the skill comes back.
func _sweep(r: Rect2, frac: float) -> void:
	var inner: Rect2 = r.grow(-1.0)
	var h: float = roundf(inner.size.y * clampf(frac, 0.0, 1.0))
	draw_rect(Rect2(inner.position + Vector2(0, inner.size.y - h), Vector2(inner.size.x, h)), Color(0, 0, 0, 0.62))
	draw_line(Vector2(inner.position.x, inner.end.y - h), Vector2(inner.end.x, inner.end.y - h), Color(UiDraw.FRAME_LIT, 0.7))


func _xp(r: Rect2) -> void:
	var p: Progression = g.player.prog
	draw_rect(r.grow(1.0), UiDraw.INK)
	draw_rect(Rect2(r.position, Vector2(r.size.x * p.xp / p.xp_to_next(), r.size.y)), Pal.c("violet_lt"))


func _tracker() -> void:
	var lines: Array = Objectives.lines(g)
	var r := Rect2(TRACKER.position, Vector2(TRACKER.size.x, 16.0 + UiDraw.LINE * lines.size()))
	UiDraw.box(self, r, Color(0.05, 0.045, 0.08, 0.75))
	for i: int in lines.size():
		UiDraw.text(self, r.position + Vector2(UiDraw.PAD, 14.0 + UiDraw.LINE * i), String(lines[i][0]), lines[i][1])


func _top_bar(r: Rect2) -> void:
	var e: Enemy = boss if is_instance_valid(boss) and not boss.dead else g.input.hovered_enemy
	if e == null or not is_instance_valid(e) or e.dead:
		return
	var col: Color = Pal.c("violet_lt") if e.rank == "boss" else (Pal.c("gold") if e.rank == "rare" else (Color("7fb2ff") if e.rank == "magic" else UiDraw.TEXT))
	draw_rect(r.grow(1.0), UiDraw.INK)
	draw_rect(r, Color(0.1, 0.04, 0.06))
	draw_rect(Rect2(r.position, Vector2(r.size.x * maxf(0.0, e.life / e.max_life), r.size.y)), Pal.c("blood"))
	draw_rect(r, UiDraw.FRAME, false, 1.0)
	UiDraw.text(self, r.position + Vector2(0, -4), "%s   (level %d)" % [e.display_name(), e.level], col, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	UiDraw.text(self, r.position + Vector2(0, 9), "%d / %d" % [ceili(e.life), roundi(e.max_life)], UiDraw.TEXT, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	if e.shrouded:
		UiDraw.text(self, r.position + Vector2(0, r.size.y + 10), "Shrouded: takes less, hits harder", Pal.c("violet_lt"), UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _hover_tips() -> void:
	var m: Vector2 = get_local_mouse_position()
	var L: Dictionary = layout(get_viewport_rect().size)
	for i: int in SLOT_KEYS.size():
		if (L["slots"][i] as Rect2).has_point(m):
			var id: String = _slot_skill(SLOT_KEYS[i])
			if id == "tonic":
				g.ui.tooltip.show_rows(["Tonic", ["Heals %d%% of life over %.1f s. Refilled at lit waylamps." % [
					roundi(float(GameData.player["tonic"]["heal_fraction"]) * 100.0), float(GameData.player["tonic"]["duration"])], UiDraw.TEXT]], m)
			elif id != "":
				g.ui.tooltip.show_rows(SkillText.rows(self, g.player, id), m)
	if (L["xp"] as Rect2).grow(3.0).has_point(m):
		var p: Progression = g.player.prog
		g.ui.tooltip.show_rows(["Level %d" % p.level, ["Experience %d / %d" % [roundi(p.xp), roundi(p.xp_to_next())], UiDraw.TEXT]], m)
	if (L["gauge"] as Rect2).grow(4.0).has_point(m) or (L["gauge_label"] as Rect2).has_point(m):
		g.ui.tooltip.show_rows(LightText.rows(g.player), m)
