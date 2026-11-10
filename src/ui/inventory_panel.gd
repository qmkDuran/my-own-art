class_name InventoryPanel
extends CanvasLayer
## A small grid of carried items. Move to select, interact to use / equip / read,
## inventory key (I / Tab / Y) to close. Item behaviour comes from data/items.json "use".

const COLUMNS := 6
const SLOTS := 12
const SLOT_SIZE := 44

var _root: Panel
var _slots: Array[Panel] = []
var _icons: Array[TextureRect] = []
var _counts: Array[Label] = []
var _title: Label
var _description: Label
var _selected := 0
var _ids: Array[String] = []


func _ready() -> void:
	layer = 15
	_build()
	_root.visible = false
	GameState.inventory.changed.connect(_refresh)


func is_open() -> bool:
	return _root.visible


func open() -> void:
	_root.visible = true
	Router.ui_modal = true
	_refresh()
	AudioManager.play_sfx("inventory_open", -6.0)


func close() -> void:
	_root.visible = false
	Router.ui_modal = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		if is_open():
			close()
		elif not Router.is_gameplay_paused():
			open()
		return
	if not is_open():
		return
	if Input.is_action_just_pressed("pause"):
		close()
	elif Input.is_action_just_pressed("move_right"):
		_select(_selected + 1)
	elif Input.is_action_just_pressed("move_left"):
		_select(_selected - 1)
	elif Input.is_action_just_pressed("move_down"):
		_select(_selected + COLUMNS)
	elif Input.is_action_just_pressed("move_up"):
		_select(_selected - COLUMNS)
	elif Input.is_action_just_pressed("interact"):
		_use_selected()


func _select(index: int) -> void:
	_selected = clampi(index, 0, SLOTS - 1)
	_refresh()


func _use_selected() -> void:
	if _selected >= _ids.size():
		return
	var item_id := _ids[_selected]
	var item := DB.item(item_id)
	var use: Dictionary = item.get("use", {})
	if item.has("weapon"):
		var equipped := GameState.inventory.equipped_weapon == item_id
		GameState.inventory.equip("" if equipped else item_id)
		AudioManager.play_sfx("ui_confirm", -6.0)
	elif use.has("heal"):
		if GameState.hp >= GameState.max_hp:
			Events.toast.emit("You're not hurt.")
			return
		GameState.heal(int(use["heal"]))
		_sync_player_health()
		GameState.inventory.remove(item_id)
		AudioManager.play_sfx(String(use.get("sfx", "pickup")))
		Events.toast.emit(String(use.get("text", "You feel a little better.")))
	elif use.has("dialogue"):
		close()
		Dialogue.run(String(use["dialogue"]))
	elif use.has("text"):
		close()
		Dialogue.run_lines([use["text"]])


func _sync_player_health() -> void:
	if Router.game and Router.game.player:
		Router.game.player.sync_health()


func _refresh() -> void:
	_ids.assign(GameState.inventory.item_ids().filter(func(id: String) -> bool: return not DB.item(id).get("hidden", false)))
	for i in SLOTS:
		var has_item := i < _ids.size()
		_icons[i].texture = Art.texture(String(DB.item(_ids[i]).get("icon", ""))) if has_item else null
		var count := GameState.inventory.count(_ids[i]) if has_item else 0
		_counts[i].text = str(count) if count > 1 else ""
		var border := UiStyle.ACCENT if i == _selected else UiStyle.BORDER
		if has_item and GameState.inventory.equipped_weapon == _ids[i]:
			border = Color("7ab0e0") if i != _selected else UiStyle.ACCENT
		_slots[i].add_theme_stylebox_override("panel", UiStyle.panel(Color(0.08, 0.08, 0.1, 0.95), border))
	if _selected < _ids.size():
		var item := DB.item(_ids[_selected])
		var equipped := GameState.inventory.equipped_weapon == _ids[_selected]
		_title.text = String(item.get("name", _ids[_selected])) + ("  (equipped)" if equipped else "")
		_description.text = String(item.get("description", ""))
	else:
		_title.text = "Inventory"
		_description.text = "Empty slot."


func _build() -> void:
	_root = Panel.new()
	var grid_width := COLUMNS * (SLOT_SIZE + 6) + 18
	_root.size = Vector2(grid_width + 260, 2 * (SLOT_SIZE + 6) + 54)
	_root.position = Vector2((960 - _root.size.x) / 2.0, 150)
	_root.add_theme_stylebox_override("panel", UiStyle.panel())
	add_child(_root)
	_root.add_child(UiStyle.label("INVENTORY  (E use, I close)", 14, UiStyle.DIM))
	(_root.get_child(0) as Label).position = Vector2(12, 8)
	for i in SLOTS:
		var slot := Panel.new()
		slot.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.position = Vector2(12 + (i % COLUMNS) * (SLOT_SIZE + 6), 36 + (i / COLUMNS) * (SLOT_SIZE + 6))
		var icon := TextureRect.new()
		icon.position = Vector2(6, 6)
		icon.size = Vector2(32, 32)
		slot.add_child(icon)
		var count := UiStyle.label("", 12)
		count.position = Vector2(30, 26)
		slot.add_child(count)
		_root.add_child(slot)
		_slots.append(slot)
		_icons.append(icon)
		_counts.append(count)
	_title = UiStyle.label("", 16, UiStyle.ACCENT)
	_title.position = Vector2(grid_width + 4, 34)
	_root.add_child(_title)
	_description = UiStyle.label("", 14)
	_description.position = Vector2(grid_width + 4, 58)
	_description.size = Vector2(240, 80)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(_description)
