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
	pause = _panel(PausePanel.new(), "Paused", Vector2(300, 190), "center")
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
	return [inventory, character, skills, passives, pause]


func blocking() -> bool:
	return hud.messages.modal() or pause.visible


func set_paused(on: bool) -> void:
	get_tree().paused = on
	pause.visible = on


func open(p: GamePanel) -> void:
	var was: bool = p.visible
	if p == passives or p == pause:
		_close_all()
	elif p == inventory:
		passives.visible = false
	else:
		for o: GamePanel in [character, skills, passives]:
			o.visible = false
	p.visible = was
	p.toggle()
	minimap.visible = not (inventory.visible or passives.visible)
	hud.tracker_hidden = character.visible or skills.visible or passives.visible


func _close_all() -> void:
	for p: GamePanel in panels():
		p.visible = false


## Keys that work whatever is under the mouse. Returns true if the event was used.
func handle_global(event: InputEvent) -> bool:
	if hud.messages.modal() and (event.is_action_pressed("click") or event.is_action_pressed("interact")):
		hud.messages.advance()
		return true
	if event.is_action_pressed("menu"):
		if panels().any(func(p: GamePanel) -> bool: return p.visible and p != pause):
			_close_all()
			minimap.visible = true
			hud.tracker_hidden = false
		else:
			set_paused(not pause.visible)
		return true
	var map: Dictionary = {"inventory": inventory, "character": character, "skills": skills, "passives": passives}
	for action: String in map:
		if event.is_action_pressed(action):
			open(map[action])
			return true
	if event.is_action_pressed("labels"):
		LabelStack.shown = not LabelStack.shown
		return true
	return false


## Fade to black, do something (a jump in place or time), fade back.
func fade_through(action: Callable) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, FADE)
	tw.tween_callback(action)
	tw.tween_property(_fade, "color:a", 0.0, FADE)


func dialogue_closed() -> void:
	if g.flags.has("nim_free") and not g.flags.has("slice_done"):
		for n: Node in get_tree().get_nodes_in_group("interactables"):
			if n is Npc and (n as Npc).npc_id == "nim" and (n as Npc).talked > 0:
				g.flags["slice_done"] = true
				hud.messages.show_end_card()
				g.mark_dirty()
