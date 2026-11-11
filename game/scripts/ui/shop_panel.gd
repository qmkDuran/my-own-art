class_name ShopPanel
extends ScreenPanel
## Pell's Pantry: buy treats and salves, one at a time, while your coins last.

const LIST_W: int = 150
const INFO_X: int = 160

var _ids: PackedStringArray = []
var _coins: Label
var _info: Label


func run() -> void:
	set_title("Pell's Pantry")
	_ids = PackedStringArray(Db.items.keys())
	var names: PackedStringArray = []
	for id: String in _ids:
		names.append("%s  %dc" % [Db.item(id)["name"], int(Db.item(id)["price"])])
	var list := MenuList.new()
	content.add_child(list)
	list.setup(names, 1, LIST_W)
	_coins = add_label("", Vector2(INFO_X, 0), "ember1")
	_info = UiKit.wrapped("", content.size.x - INFO_X)
	_info.position = Vector2(INFO_X, 16)
	content.add_child(_info)
	list.index_changed.connect(_describe)
	_describe(0)
	while true:
		var i: int = await list.pick()
		if i < 0:
			return
		buy(_ids[i])
		_describe(i)


func _describe(i: int) -> void:
	_coins.text = "Coins: %d" % Game.coins
	_info.text = String(Db.item(_ids[i])["text"]) + "\nYou have %d." % Game.bag.count(_ids[i])


static func buy(id: String) -> bool:
	var price: int = int(Db.item(id)["price"])
	if Game.coins < price:
		Audio.sfx("bump")
		return false
	Game.coins -= price
	Game.bag.add(id)
	Audio.sfx("buy")
	return true
