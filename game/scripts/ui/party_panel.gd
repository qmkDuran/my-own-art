class_name PartyPanel
extends ScreenPanel
## Your team in a 2x3 grid. Accept opens a small menu: Summary, Lead (move to the front), Back.

const COLS: int = 2
const GAP: Vector2 = Vector2(4, 4)
const ACTIONS: PackedStringArray = ["Summary", "Lead", "Back"]

var _cards: Array[PartyCard] = []
var _index: int = 0
var _clicked_index: int = -1


func run() -> void:
	set_title("Team")
	while true:
		_rebuild()
		var i: int = await _pick_card()
		if i < 0:
			return
		await _card_menu(i)


func _rebuild() -> void:
	clear_content()
	_cards.clear()
	for i: int in Game.party.size():
		var card := PartyCard.new().setup(Game.party[i])
		card.position = Vector2((i % COLS) * (PartyCard.SIZE.x + GAP.x), (i / COLS) * (PartyCard.SIZE.y + GAP.y))
		card.gui_input.connect(func(ev: InputEvent) -> void: _clicked(ev, i))
		content.add_child(card)
		_cards.append(card)
	_select(mini(_index, _cards.size() - 1))



func _clicked(ev: InputEvent, i: int) -> void:
	if UiKit.is_click(ev):
		_clicked_index = i


func _select(i: int) -> void:
	_index = i
	for k: int in _cards.size():
		_cards[k].set_selected(k == i)


func _pick_card() -> int:
	_clicked_index = -1
	while true:
		await get_tree().process_frame
		if _clicked_index >= 0:
			_select(_clicked_index)
			return _clicked_index
		if Input.is_action_just_pressed("cancel"):
			Audio.sfx("cancel")
			return -1
		if Input.is_action_just_pressed("accept"):
			Audio.sfx("select")
			return _index
		_steer()
	return -1


func _steer() -> void:
	var step: int = 0
	for pair: Array in [["move_right", 1], ["move_left", -1], ["move_down", COLS], ["move_up", -COLS]]:
		if Input.is_action_just_pressed(String(pair[0])):
			step = int(pair[1])
	if step != 0 and not _cards.is_empty():
		Audio.sfx("move")
		_select(posmod(_index + step, _cards.size()))


func _card_menu(i: int) -> void:
	var at: Vector2 = _cards[i].position + Vector2(84, 16)
	at.x = minf(at.x, content.size.x - 64)
	var box := UiKit.panel(Rect2(at, Vector2(64, 44)))
	content.add_child(box)
	var list := MenuList.new()
	box.add_child(list)
	list.setup(ACTIONS, 1, 52)
	list.position = Vector2(4, 3)
	var choice: int = await list.pick()
	box.queue_free()
	if choice == 0:
		var summary := SummaryPanel.new()
		add_child(summary)
		await summary.run_for(i)
		summary.queue_free()
	elif choice == 1 and i > 0:
		var c: Creature = Game.party[i]
		Game.party.remove_at(i)
		Game.party.insert(0, c)
		_index = 0
