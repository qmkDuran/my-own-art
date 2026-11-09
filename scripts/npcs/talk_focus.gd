class_name TalkFocus
extends RefCounted
## Which townsperson Emberoo is close enough to talk to, if any. While someone is in reach,
## the talk keys (F and E) start the conversation instead of their usual job (Trainer's Aid,
## the skill in slot E), so PlayerInput asks here first.

## The keys that talk, as input actions.
const TALK_ACTIONS: Array[String] = ["trainer_aid", "skill_3"]

## Untyped on purpose: it may hold an Npc freed with its zone.
static var _focused: Variant = null


## `npc` is in reach: it takes the talk keys (unless someone else already has them).
static func offer(npc: Node2D) -> void:
	if not has_focus():
		_focused = npc


## `npc` is out of reach again.
static func release(npc: Node2D) -> void:
	if is_instance_valid(_focused) and _focused == npc:
		_focused = null


static func is_focused(npc: Node2D) -> bool:
	return has_focus() and _focused == npc


static func has_focus() -> bool:
	return is_instance_valid(_focused) and (_focused as Node2D).is_inside_tree()


## True when `action` would start a conversation now instead of doing its usual job.
static func takes_action(action: String) -> bool:
	return has_focus() and TALK_ACTIONS.has(action)
