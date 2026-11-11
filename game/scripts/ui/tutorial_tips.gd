class_name TutorialTips
extends Control
## Gentle, one-at-a-time hints the first time each system comes up: loot (I), the first level, a new skill (K),
## passives (P), waylamps, rare items, running out of Oil, and later the loot filter (L). Each is a small panel
## with a key hint and "Got it" (Esc also dismisses). Seen tips are campaign flags, so they never repeat.

const W: float = 300.0
const PAD: float = 10.0
const BTN := Vector2(70, 18)
const CHECK_EVERY: float = 0.5
const NEAR: float = 220.0
const FILTER_LEVEL: int = 5
const TIPS: Dictionary = {
	"loot": ["Loot", "Something dropped. Click it to pick it up, then open your inventory to wear it.", "I"],
	"rare": ["A rare find", "Coloured names are rarer. Hover any item to see its stats compared with what you wear.", "hover"],
	"level": ["Level up", "Skills grow as you use them. Specialise one in the skill tree and spend its points.", "K"],
	"skill": ["A new skill", "You learned a new skill. Open the skill tree to read it and put it on your bar.", "K"],
	"passives": ["Passives", "From now on every level gives a passive point. Spend it on the passive tree.", "P"],
	"waylamp": ["A waylamp", "Click it and hold your ground while it catches. Lit, it refills tonics and lets you travel.", "click"],
	"oil": ["Out of Oil", "Skills cost Oil; it refills slowly. Wickbolt is free. Tonics (1) mend your life.", "1"],
	"filter": ["The loot filter", "Too much loot? Hide what you don't want to see.", "L"],
}

var g: Game
var _queue: Array[String] = []
var _open: String = ""
var _t: float = 0.0
var _skills_known: int = 0


func setup(game: Game) -> void:
	g = game
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_skills_known = g.player.prog.skills.size()


func is_open() -> bool:
	return _open != ""


func dismiss() -> void:
	if _open != "":
		Session.campaign.set_flag("tip_" + _open)
		_open = ""
		visible = false


## Off in automated runs (tests, shots, the bot), unless a shot asks for them.
static var forced: bool = false


static func active() -> bool:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	return forced or not Dev.AUTOMATED.any(func(a: String) -> bool: return args.has(a))


func _process(delta: float) -> void:
	if not active():
		return
	if g.ui.skills.visible and SpecSlotsView.needs_card():   # the specialisation card speaks first; tips wait
		visible = false
		return
	visible = _open != ""
	_t -= delta
	if _t <= 0.0 and not get_tree().paused:
		_t = CHECK_EVERY
		_check()
	if _open == "" and not _queue.is_empty() and not g.hud.messages.modal():
		_open = _queue.pop_front()
		visible = true
		Audio.sfx("ui_open", -8.0)
	if visible:
		var r: Rect2 = panel_rect(get_viewport_rect().size)
		position = r.position
		size = r.size
		queue_redraw()


func _want(id: String) -> void:
	if not Session.campaign.flags.has("tip_" + id) and _open != id and not _queue.has(id):
		_queue.append(id)


func _check() -> void:
	var p: Player = g.player
	for n: Node in get_tree().get_nodes_in_group("ground_items"):
		var gi := n as GroundItem
		if gi.global_position.distance_to(p.global_position) < NEAR:
			_want("loot")
			if ["rare", "unique", "set"].has(String(gi.item["rarity"])):
				_want("rare")
	if p.prog.level >= 2:
		_want("level")
	if p.prog.passive_points() > 0:
		_want("passives")
	if p.prog.skills.size() > _skills_known:
		_skills_known = p.prog.skills.size()
		_want("skill")
	for l: Waylamp in g.lamps:
		if not l.lit and l.global_position.distance_to(p.global_position) < NEAR:
			_want("waylamp")
	if p.oil < p.skills.cost_of("flare"):
		_want("oil")
	if p.prog.level >= FILTER_LEVEL:
		_want("filter")


static func panel_rect(vs: Vector2) -> Rect2:
	var cluster: Rect2 = Hud.layout(vs)["cluster"]
	return Rect2(roundf((vs.x - W) / 2.0), cluster.position.y - 86.0, W, 74.0)


func button_rect() -> Rect2:
	return Rect2(size.x - BTN.x - PAD, size.y - BTN.y - 8.0, BTN.x, BTN.y)


func _draw() -> void:
	if _open == "":
		return
	var tip: Array = TIPS[_open]
	UiDraw.box(self, Rect2(Vector2.ZERO, size))
	UiDraw.text(self, Vector2(PAD, 16), String(tip[0]), UiDraw.GOLD, UiDraw.BODY)
	var key: String = String(tip[2])
	UiDraw.box(self, Rect2(size.x - PAD - 40.0, 5.0, 40.0, 15.0), Color(0.14, 0.1, 0.08), UiDraw.FRAME_LIT)
	UiDraw.text(self, Vector2(size.x - PAD - 40.0, 16), key.to_upper() if key.length() <= 1 else key, UiDraw.GOLD, UiDraw.SMALL,
		HORIZONTAL_ALIGNMENT_CENTER, 40.0)
	var y: float = 32.0
	for line: String in UiDraw.wrap(self, String(tip[1]), size.x - PAD * 2.0, UiDraw.SMALL):
		UiDraw.text(self, Vector2(PAD, y), line, UiDraw.TEXT, UiDraw.SMALL)
		y += 11.0
	var b: Rect2 = button_rect()
	UiDraw.box(self, b, Color(0.14, 0.1, 0.08), UiDraw.FRAME)
	UiDraw.text(self, b.position + Vector2(0, 13), "Got it", UiDraw.GOLD, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, b.size.x)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed:
		accept_event()
		if button_rect().has_point(mb.position):
			Audio.sfx("ui_click", -8.0)
			dismiss()
