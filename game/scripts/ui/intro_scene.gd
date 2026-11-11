class_name IntroScene
extends Control
## The opening: story cards about the Hush, then Keeper Tamsin offers three young wildkin and you choose your
## first companion (left/right to look, accept to choose).

signal done

const STARTERS: Array[String] = ["mossfawn", "emberkit", "ripplet"]
const SPACING: int = 92
const ROW_Y: int = 34

var dialog: DialogueBox
var _bg: TextureRect
var _picks: Array[TextureRect] = []
var _info: Panel
var _index: int = 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg = TextureRect.new()
	_bg.position = ((get_viewport_rect().size - Vector2(320, 180)) / 2).floor()
	add_child(_bg)
	dialog = DialogueBox.new()
	add_child(dialog)


func run() -> void:
	Audio.music("title")
	_bg.texture = load("res://art/scenes/intro_hush.png")
	await dialog.say(Db.lines("intro", {}))
	_bg.texture = load("res://art/scenes/intro_shoot.png")
	_show_starters()
	await dialog.say(Db.lines("keeper_choice", {}), "Tamsin")
	var chosen: String = await choose()
	Game.choose_starter(chosen)
	Audio.sfx("befriend")
	await dialog.say(Db.lines("keeper_after_choice", {}), "Tamsin")
	done.emit()


func _show_starters() -> void:
	var view: Vector2 = get_viewport_rect().size
	for i: int in STARTERS.size():
		var x: float = view.x / 2 + (i - 1) * SPACING - 40
		add_child(UiKit.panel(Rect2(x + 4, ROW_Y + 70, 72, 14), "cream", "ink"))
		var t := TextureRect.new()
		t.texture = UiKit.creature_tex(STARTERS[i], "front")
		t.position = Vector2(x, ROW_Y)
		add_child(t)
		_picks.append(t)


## Lets the player look over the three and pick one; returns its species id.
func choose() -> String:
	while true:
		await _browse()
		_info.visible = false
		var c: Dictionary = Db.species[STARTERS[_index]]
		var yes: int = await dialog.ask("Walk with %s, the %s wildkin?" % [c["name"], Db.element_name(String(c["element"]))],
			PackedStringArray(["Yes", "No"]))
		if yes == 0:
			break
	if _info != null:
		_info.queue_free()
	return STARTERS[_index]


func _browse() -> void:
	_highlight()
	while not Game.fast:
		await get_tree().process_frame
		if Input.is_action_just_pressed("accept"):
			Audio.sfx("select")
			return
		var step: int = int(Input.is_action_just_pressed("move_right")) - int(Input.is_action_just_pressed("move_left"))
		if step != 0:
			_index = posmod(_index + step, STARTERS.size())
			Audio.sfx("move")
			_highlight()


func _highlight() -> void:
	for i: int in _picks.size():
		_picks[i].position.y = ROW_Y - (6 if i == _index else 0)
	if _info != null:
		_info.queue_free()
	var c: Dictionary = Db.species[STARTERS[_index]]
	var view: Vector2 = get_viewport_rect().size
	_info = UiKit.panel(Rect2(4, view.y - 50, view.x - 8, 46))
	add_child(_info)
	var heading := UiKit.label("%s  -  %s" % [c["name"], Db.element_name(String(c["element"]))], "ink")
	heading.position = Vector2(6, 1)
	_info.add_child(heading)
	var note := UiKit.wrapped(String(c["journal"]), view.x - 20, "ink2")
	note.position = Vector2(6, 14)
	_info.add_child(note)
