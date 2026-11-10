class_name PickupInteractable
extends Interactable
## Adds an item to the inventory and removes itself for good (sets "taken:<id>").

var item_id := ""
var amount := 1
var taken_flag := ""
var after_ref := ""


func setup(data: Dictionary, entity_id: String) -> void:
	item_id = String(data.get("item", ""))
	amount = int(data.get("count", 1))
	verb = String(data.get("verb", "Pick up"))
	taken_flag = "taken:" + entity_id
	after_ref = String(data.get("dialogue", ""))
	configure_lock(data)


func prompt() -> String:
	return "%s %s" % [verb, String(DB.item(item_id).get("name", item_id))]


func _perform(_player: Player) -> void:
	GameState.inventory.add(item_id, amount)
	var item := DB.item(item_id)
	if item.has("weapon") and GameState.inventory.equipped_weapon.is_empty():
		GameState.inventory.equip(item_id)
	AudioManager.play_sfx("pickup")
	Events.toast.emit("Picked up: %s" % String(item.get("name", item_id)))
	GameState.flags.set_flag(taken_flag)
	if not after_ref.is_empty():
		await Dialogue.run(after_ref)
