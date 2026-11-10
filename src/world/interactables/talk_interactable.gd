class_name TalkInteractable
extends Interactable
## Starts a conversation with an NPC; the NPC turns to face the player.

var ref := ""
var visual: CharacterVisual


func setup(data: Dictionary, npc_visual: CharacterVisual) -> void:
	verb = String(data.get("verb", "Talk"))
	ref = String(data.get("dialogue", ""))
	visual = npc_visual
	configure_lock(data)


func _perform(player: Player) -> void:
	if visual:
		visual.facing = (player.global_position - global_position).normalized()
	await Dialogue.run(ref)
