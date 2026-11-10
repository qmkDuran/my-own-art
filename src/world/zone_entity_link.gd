class_name ZoneEntityLink
extends Node
## Attached to every entity a Zone builds. Holds the entity's data id and its visibility
## condition; the Zone re-applies it whenever a flag changes, so entities appear and
## disappear with the story (e.g. "if": "vanished").

var entity_id := ""
var condition: Variant = null
var active := true
var _applied := false


static func gone_flag(id: String) -> String:
	return "gone:" + id


func is_satisfied() -> bool:
	if not entity_id.is_empty() and GameState.flags.is_set(gone_flag(entity_id)):
		return false
	return Condition.check(condition)


func apply() -> void:
	var now := is_satisfied()
	if _applied and now == active:
		return
	_applied = true
	active = now
	var host := get_parent()
	if host is CanvasItem:
		(host as CanvasItem).visible = now
	host.process_mode = Node.PROCESS_MODE_INHERIT if now else Node.PROCESS_MODE_DISABLED
