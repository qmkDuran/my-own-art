class_name GameUi
extends CanvasLayer
## Every screen-space piece of the session: HUD, minimap, the panels, the menu, the tooltip (drawn last, above
## all). Opens and closes panels (one left, one right; the passive tree takes the middle alone) and answers the
## global keys (I C K P, Alt, Esc, F/click for dialogue).

const LAYER: int = 10
const FADE: float = 0.3

var g: Game
var hud: Hud
var minimap: Minimap
var inventory: InventoryPanel
var character: CharacterPanel
var skills: SkillPanel
var passives: PassivePanel
var pause: PausePanel
var quests: QuestPanel
var filter: FilterPanel
var travel: TravelPanel
var stash: StashPanel
var respec: RespecPanel
var bestiary: BestiaryPanel
var forge: ForgePanel
var help: HelpPanel
var tips: TutorialTips
var tooltip: TooltipLayer
var _fade: ColorRect


func setup(game: Game) -> void:
	g = game
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud = Hud.new()
	add_child(hud)
	hud.setup(g)
	minimap = Minimap.new()
	add_child(minimap)
	minimap.setup(g)
	inventory = _panel(InventoryPanel.new(), "Inventory", Vector2(300, 392), "right")
	character = _panel(CharacterPanel.new(), "Character", Vector2(300, 436), "left")
	skills = _panel(SkillPanel.new(), "Skills", Vector2(560, 400), "left")
	passives = _panel(PassivePanel.new(), "Passives", Vector2(660, 400), "center")
	pause = _panel(PausePanel.new(), "Paused", PausePanel.panel_size_for(), "center")
	quests = _panel(QuestPanel.new(), "Quests", Vector2(360, 400), "left")
	filter = _panel(FilterPanel.new(), "Loot Filter", Vector2(300, 330), "center")
	travel = _panel(TravelPanel.new(), "Nim's Maps", Vector2(320, 200), "center")
	stash = _panel(StashPanel.new(), "Fenn's Lockers", Vector2(280, 250), "left")
	respec = _panel(RespecPanel.new(), "The Order's Ledger", Vector2(320, 400), "center")
	bestiary = _panel(BestiaryPanel.new(), "Bestiary", Vector2(400, 400), "left")
	forge = _panel(ForgePanel.new(), "The Ember Forge", Vector2(340, 330), "left")
	help = _panel(HelpPanel.new(), "Help", Vector2(560, 400), "center") as HelpPanel
	tips = TutorialTips.new()
	add_child(tips)
	tips.setup(g)
	tooltip = TooltipLayer.new()
	add_child(tooltip)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func _panel(p: GamePanel, title: String, sz: Vector2, side: String) -> GamePanel:
	add_child(p)
	p.setup(g, title, sz, side)
	return p


func panels() -> Array[GamePanel]:
	return [inventory, character, skills, passives, pause, quests, filter, travel, stash, respec, bestiary, forge, help]


func left_panels() -> Array[GamePanel]:
	return [character, skills, passives, quests, stash, bestiary, forge]


func center_panels() -> Array[GamePanel]:
	return [passives, pause, filter, travel, respec, help]


func blocking() -> bool:
	return hud.messages.modal() or pause.visible


func set_paused(on: bool) -> void:
	get_tree().paused = on
	pause.visible = on


## One panel on the left, one on the right (the inventory); centre panels stand alone.
func open(p: GamePanel) -> void:
	var was: bool = p.visible
	if center_panels().has(p):
		close_all()
	elif p == inventory:
		for o: GamePanel in center_panels():
			o.visible = false
	else:
		for o: GamePanel in left_panels() + center_panels():
			o.visible = false
	p.visible = was
	p.toggle()
	if (p == stash or p == forge) and p.visible:
		inventory.visible = true
	minimap.visible = not (inventory.visible or panels().any(func(o: GamePanel) -> bool: return o.visible and center_panels().has(o)))
	hud.tracker_hidden = left_panels().any(func(o: GamePanel) -> bool: return o.visible) or center_panels().any(func(o: GamePanel) -> bool: return o.visible)


## Close every open panel (a player pressing Esc; the demo bot after it touches a waylamp).
func close_all() -> void:
	for p: GamePanel in panels():
		p.visible = false


## The UI layer always processes, so its keys work while the game is paused (Esc closes the menu again).
func _unhandled_input(event: InputEvent) -> void:
	if handle_global(event):
		get_viewport().set_input_as_handled()


## Keys that work whatever is under the mouse. Returns true if the event was used.
func handle_global(event: InputEvent) -> bool:
	if hud.messages.modal() and (event.is_action_pressed("click") or event.is_action_pressed("interact")):
		hud.messages.advance()
		return true
	if event.is_action_pressed("menu"):
		escape()
		return true
	if get_tree().paused and not help.visible:
		return false
	var map: Dictionary = {"inventory": inventory, "character": character, "skills": skills, "passives": passives,
		"quests": quests, "filter": filter, "help": help}
	for action: String in map:
		if event.is_action_pressed(action):
			open(map[action])
			return true
	if event.is_action_pressed("map"):
		minimap.toggle_large()
		return true
	if event.is_action_pressed("labels"):
		LabelStack.shown = not LabelStack.shown
		return true
	return false


## Esc closes the top-most thing first: a tip, then Help, then other panels, and only then opens or closes the menu.
func escape() -> void:
	if tips.is_open():
		tips.dismiss()
	elif help.visible:
		help.toggle()
	elif panels().any(func(p: GamePanel) -> bool: return p.visible and p != pause):
		close_all()
		minimap.visible = true
		hud.tracker_hidden = false
	else:
		set_paused(not pause.visible)


## Fade to black, do something (a jump in place or time), fade back.
func fade_through(action: Callable) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, FADE)
	tw.tween_callback(action)
	tw.tween_property(_fade, "color:a", 0.0, FADE)


## A person's service after a talk: travel (Nim's maps), stash (Fenn's lockers), respec (Ottilie's ledger),
## bestiary (Lio's shelf), forge (Fenn's anvil).
func open_service(service: String) -> void:
	var map: Dictionary = {"travel": travel, "stash": stash, "respec": respec, "bestiary": bestiary, "forge": forge}
	if map.has(service):
		open(map[service])
