class_name BagPanel
extends ScreenPanel
## The bag: items with counts and what they do. Salves heal a team member; treats given outside battle
## deepen a friend's Bond (more if it is a favourite).

const LIST_W: int = 130
const INFO_X: int = 140

var _ids: PackedStringArray = []
var _info: Label
var _icon: TextureRect


func run() -> void:
	set_title("Bag")
	while true:
		clear_content()
		_ids = Game.bag.ids()
		if _ids.is_empty():
			add_label("The bag is empty.", Vector2(0, 0), "dusk")
			await wait_close()
			return
		var i: int = await _pick_item()
		if i < 0:
			return
		await _use(_ids[i])


func _pick_item() -> int:
	var names: PackedStringArray = []
	for id: String in _ids:
		names.append("%s x%d" % [Db.item(id)["name"], Game.bag.count(id)])
	var list := MenuList.new()
	content.add_child(list)
	list.max_rows = int(content.size.y / MenuList.ROW_H)
	list.setup(names, 1, LIST_W)
	_icon = add_icon("res://art/ui/item_%s.png" % _ids[0], Vector2(INFO_X, 0))
	_info = add_label("", Vector2(INFO_X, 20), "ink")
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.size = Vector2(content.size.x - INFO_X, 60)
	list.index_changed.connect(_describe)
	_describe(0)
	return await list.pick()


func _describe(i: int) -> void:
	_icon.texture = load("res://art/ui/item_%s.png" % _ids[i])
	_info.text = String(Db.item(_ids[i])["text"])


func _use(id: String) -> void:
	var target: int = await _pick_friend()
	if target < 0:
		return
	var c: Creature = Game.party[target]
	Game.bag.take(id)
	if Db.item(id)["kind"] == "heal":
		c.heal(int(Db.item(id)["amount"]))
		Audio.sfx("heal")
	else:
		Bond.gain(c, "liked_treat" if TrustRules.likes(c.species_id, id) else "treat")
		Audio.sfx("trust")


func _pick_friend() -> int:
	var names: PackedStringArray = []
	for c: Creature in Game.party:
		names.append("%s %d/%d" % [c.display_name(), c.hp, c.max_hp()])
	var box := UiKit.panel(Rect2(INFO_X - 4, 70, content.size.x - INFO_X + 4, names.size() * MenuList.ROW_H + 8))
	content.add_child(box)
	var list := MenuList.new()
	box.add_child(list)
	list.setup(names, 1, int(box.size.x) - 10)
	list.position = Vector2(4, 3)
	var i: int = await list.pick()
	box.queue_free()
	return i
