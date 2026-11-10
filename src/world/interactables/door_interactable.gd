class_name DoorInteractable
extends Interactable
## Moves the player to another zone ("to") at a named spawn point, with a fade.

var target_zone := ""
var target_spawn := ""


func setup(data: Dictionary) -> void:
	verb = String(data.get("verb", "Enter"))
	target_zone = String(data.get("to", ""))
	target_spawn = String(data.get("spawn", ""))
	configure_lock(data)


func _perform(_player: Player) -> void:
	await Router.go_to_zone(target_zone, target_spawn)
