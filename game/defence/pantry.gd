class_name Pantry
extends RefCounted
## The café's store of ingredients, kept between nights in user://pantry.json. A night fills a bag; surviving
## the night empties the whole bag into the pantry, fainting keeps only a share of it.

const SAVE_PATH: String = "user://pantry.json"

var stock: Dictionary = {}
var save_path: String = SAVE_PATH


func load_stock() -> void:
	stock = {}
	if FileAccess.file_exists(save_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if parsed is Dictionary:
			stock = parsed


## Adds a night's bag, keeping only a share of each ingredient (rounded down), and saves.
func store(bag: Dictionary, share: float) -> Dictionary:
	var kept: Dictionary = {}
	for item: String in bag:
		var amount: int = int(floor(int(bag[item]) * share))
		if amount > 0:
			kept[item] = amount
			stock[item] = int(stock.get(item, 0)) + amount
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(stock))
	return kept
