extends Node
## UI layout at several screen shapes (16:9, 16:10, 1366x768, 4:3, 2:1): every screen is built in a sub-viewport
## of that size and each visible control must lie inside the screen and inside the panel that holds it, and
## panels side by side must not overlap.

const SIZES: Array[Vector2i] = [Vector2i(320, 180), Vector2i(320, 200), Vector2i(341, 192), Vector2i(320, 240),
	Vector2i(360, 180)]
const SCREENS: Array[String] = ["title", "starter", "dialogue", "menu", "party", "summary", "journal", "bag", "shop",
	"battle", "battle_moves", "evolution"]

var _problems: PackedStringArray = []


func _ready() -> void:
	Game.fast = true
	TimingRing.autopilot = "good"
	_setup_game()
	for s: Vector2i in SIZES:
		for screen: String in SCREENS:
			await _check(screen, s)
	for p: String in _problems:
		print("UI problem: ", p)
	print("UI %s (%d screens x %d sizes, %d problems)" % ["PASS" if _problems.is_empty() else "FAIL",
		SCREENS.size(), SIZES.size(), _problems.size()])
	get_tree().quit(0 if _problems.is_empty() else 1)


func _setup_game() -> void:
	Game.new_game()
	Game.choose_starter("drizzlesnail")
	for id: String in ["thistlehog", "kindlemoth", "cobblemole", "puffwren", "rivermane"]:
		Game.befriend(Creature.create(id, 9))
	for id: String in Db.species:
		Game.journal.befriend(id)
	for id: String in Db.items:
		Game.bag.add(id, 99)
	Game.coins = 99999


func _check(screen: String, size: Vector2i) -> void:
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	add_child(vp)
	var root: Node = await _build(screen, vp)
	for i: int in 6:
		await get_tree().process_frame
	_inspect(vp, "%s@%dx%d" % [screen, size.x, size.y])
	vp.queue_free()
	await get_tree().process_frame


func _build(screen: String, vp: SubViewport) -> Node:
	match screen:
		"title":
			return _add(vp, TitleScreen.new())
		"starter":
			var intro: IntroScene = _add(vp, IntroScene.new())
			intro._show_starters()
			intro._highlight()
			return intro
		"dialogue", "menu":
			var w: Overworld = _add(vp, Overworld.new())
			if screen == "menu":
				w.interactions.open_menu()
			else:
				w.dialog.say(Db.lines("gran", {}), "Mender Ilse")
			return w
		"battle", "battle_moves":
			return await _battle(vp, screen == "battle_moves")
		"evolution":
			var e: EvolutionScene = _add(vp, EvolutionScene.new())
			e.run(Creature.create("emberkit", 7), "hearthfox")
			return e
	return _panel(vp, screen)


func _panel(vp: SubViewport, screen: String) -> Node:
	var p: ScreenPanel = {"party": PartyPanel, "summary": SummaryPanel, "journal": JournalPanel, "bag": BagPanel,
		"shop": ShopPanel}[screen].new()
	_add(vp, p)
	if screen == "summary":
		p.run_for(5)
	else:
		p.run()
	return p


func _battle(vp: SubViewport, moves: bool) -> Node:
	var b := BattleScene.new()
	b.kind = "wild"
	var holder := Node.new()
	vp.add_child(holder)
	holder.add_child(b)
	var foes: Array[Creature] = [Creature.create("drizzlesnail", 7)]
	b.run(foes)
	for i: int in 30:
		await get_tree().process_frame
	if moves:
		var ev := InputEventAction.new()
		ev.action = "accept"
		ev.pressed = true
		vp.push_input(ev)
	return b


func _add(vp: SubViewport, n: Node) -> Node:
	vp.add_child(n)
	return n


func _inspect(vp: SubViewport, tag: String) -> void:
	var screen := Rect2(Vector2.ZERO, Vector2(vp.size))
	for c: Control in _controls(vp):
		var r: Rect2 = _rect(c)
		if r.size.x <= 0 or r.size.y <= 0:
			continue
		if not screen.grow(0.5).encloses(r):
			_problems.append("%s: %s %s leaves the screen (%s)" % [tag, c.get_class(), _name(c), r])
		var holder: Panel = _holder(c)
		if holder != null and not _rect(holder).grow(0.5).encloses(r):
			_problems.append("%s: %s %s spills out of its panel" % [tag, c.get_class(), _name(c)])
	_check_siblings(vp, tag)


func _check_siblings(vp: SubViewport, tag: String) -> void:
	var panels: Array[Panel] = []
	for c: Control in _controls(vp):
		if c is Panel and _holder(c) == null:
			panels.append(c)
	for i: int in panels.size():
		for k: int in range(i + 1, panels.size()):
			var a: Panel = panels[i]
			var b: Panel = panels[k]
			if a.get_parent() == b.get_parent() and _rect(a).intersects(_rect(b)):
				_problems.append("%s: panels %s and %s overlap" % [tag, _name(a), _name(b)])


func _name(c: Control) -> String:
	if c is Label:
		return "'%s'" % (c as Label).text.left(24)
	return str(c.get_path()).get_file()


func _rect(c: Control) -> Rect2:
	var r: Rect2 = c.get_global_rect()
	if c is Label:
		var l := c as Label
		var font: Font = l.get_theme_font("font")
		var fs: int = l.get_theme_font_size("font_size")
		if l.autowrap_mode == TextServer.AUTOWRAP_OFF:
			r.size.x = maxf(1.0, font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		r.size.y = maxf(1.0, l.get_line_count() * font.get_height(fs) - 2)
		if l.text == "":
			r.size = Vector2.ZERO
	return r


func _holder(c: Control) -> Panel:
	var p: Node = c.get_parent()
	while p != null and p is Control:
		if p is Panel:
			return p
		p = p.get_parent()
	return null


func _controls(n: Node) -> Array[Control]:
	var out: Array[Control] = []
	for child: Node in n.get_children():
		if child is CanvasItem and not (child as CanvasItem).visible:
			continue
		if child is Control:
			out.append(child)
		out.append_array(_controls(child))
	return out
