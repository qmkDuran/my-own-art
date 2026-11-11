extends Node
## --ui: lays out the HUD and every panel for each supported screen size (16:9 and 16:10, as Godot's integer
## stretch makes them) and checks nothing is cut off and nothing overlaps; also that tooltips stay on screen and
## every node name fits its box.

const SIZES: Array[Vector2] = [Vector2(960, 540), Vector2(1280, 720), Vector2(1366, 768), Vector2(1600, 900),
	Vector2(960, 600), Vector2(1280, 800), Vector2(1440, 900), Vector2(1680, 1050)]

var _fails: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	for i: int in 10:
		await get_tree().process_frame
	var g: Game = Game.current
	for vs: Vector2 in SIZES:
		_check_size(g, vs)
	_check_names(g)
	_check_menu_labels(g)
	if not HudButtons.labels_fit(g.ui.hud):
		_fails.append("a HUD button label touches its border")
	print("UI %s (%d sizes, %d problems)" % ["PASS" if _fails.is_empty() else "FAIL", SIZES.size(), _fails.size()])
	for f: String in _fails:
		print("UI problem: ", f)
	get_tree().quit(0 if _fails.is_empty() else 1)


func _check_size(g: Game, vs: Vector2) -> void:
	var screen := Rect2(Vector2.ZERO, vs)
	var L: Dictionary = Hud.layout(vs)
	var named: Dictionary = {"life orb": L["life"], "oil orb": L["oil"], "light gauge": L["gauge_label"].merge(L["gauge"]),
		"xp": L["xp"], "tracker": L["tracker"], "minimap": (L["minimap"] as Rect2).grow(2.0), "top bar": L["bar"]}
	for i: int in (L["slots"] as Array).size():
		named["slot %d" % i] = L["slots"][i]
	for i: int in (L["buttons"] as Array).size():
		named["hud button %d" % i] = L["buttons"][i]
	if not screen.encloses(TutorialTips.panel_rect(vs)):
		_fails.append("tutorial tip cut off at %s" % vs)
	for k: String in named:
		if not screen.encloses(named[k]):
			_fails.append("%s cut off at %s" % [k, vs])
	var keys: Array = named.keys()
	for i: int in keys.size():
		for j: int in range(i + 1, keys.size()):
			if (named[keys[i]] as Rect2).intersects(named[keys[j]]):
				_fails.append("%s overlaps %s at %s" % [keys[i], keys[j], vs])
	for p: GamePanel in g.ui.panels():
		var r: Rect2 = p.place_rect(vs)
		p.size = r.size
		var rects: Array[Rect2] = p.layout_rects()
		for i: int in rects.size():                         # everything a panel draws stays inside it, columns apart
			var inner: Rect2 = rects[i]
			for j: int in range(i + 1, rects.size()):
				if inner.intersects(rects[j]):
					_fails.append("%s panel: content blocks %d and %d overlap at %s" % [p.title, i, j, vs])
			if not Rect2(Vector2.ZERO, r.size).encloses(inner):
				_fails.append("%s panel content %s spills out of %s at %s" % [p.title, inner, r.size, vs])
		if not screen.encloses(r):
			_fails.append("%s panel cut off at %s" % [p.title, vs])
		if r.intersects(L["cluster"]):
			_fails.append("%s panel covers the hotbar at %s" % [p.title, vs])
	if g.ui.skills.place_rect(vs).intersects(g.ui.inventory.place_rect(vs)):
		_fails.append("skills and inventory overlap at %s" % vs)
	if g.ui.character.place_rect(vs).intersects(g.ui.inventory.place_rect(vs)):
		_fails.append("character and inventory overlap at %s" % vs)


func _check_names(g: Game) -> void:
	var ci: CanvasItem = g.ui.skills
	for id: String in ["wickbolt", "flare", "lantern_toss", "moth_swarm"]:
		for n: Dictionary in GameData.skill(id)["nodes"]:
			var shown: String = String(n["name"]) if UiDraw.text_width(ci, String(n["name"]), UiDraw.SMALL) <= SkillPanel.NODE.x - 6.0 else String(n["name"]).split(" ")[0]
			if UiDraw.text_width(ci, shown, UiDraw.SMALL) > SkillPanel.NODE.x - 4.0:
				_fails.append("skill node name '%s' does not fit" % n["name"])
	for tree: String in GameData.passives["trees"]:
		for n: Dictionary in GameData.passives["trees"][tree]["nodes"]:
			var w: float = PassivePanel.NODE.x - 29.0
			var shown: String = String(n["name"]) if UiDraw.text_width(ci, String(n["name"]), UiDraw.SMALL) <= w else String(n["name"]).split(" ")[-1]
			if UiDraw.text_width(ci, shown, UiDraw.SMALL) > w:
				_fails.append("passive node name '%s' does not fit" % n["name"])


## Every Esc-menu label fits inside its button.
func _check_menu_labels(g: Game) -> void:
	var pause: PausePanel = g.ui.pause
	pause.size = PausePanel.panel_size_for()
	for i: int in PausePanel.ITEMS.size():
		var w: float = UiDraw.text_width(pause, pause._label(PausePanel.ITEMS[i]), UiDraw.BODY)
		if w > PausePanel.BTN.x - 6.0:
			_fails.append("menu label '%s' is wider than its button" % pause._label(PausePanel.ITEMS[i]))
