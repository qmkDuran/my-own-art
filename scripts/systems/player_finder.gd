class_name PlayerFinder
extends RefCounted
## Finds the player creature (the one node in the "player" group) and its components,
## so nothing else needs to know how the player is found.
##
## Enemies ask every frame, so the player is remembered once found; the group is only
## searched again once that creature has left the tree (e.g. the zone was reloaded).

const GROUP := "player"

## Untyped on purpose: it may hold a creature that has since been freed (e.g. a zone reload),
## and a freed object can't be passed to typed code; is_instance_valid checks it first.
static var _player: Variant = null


## The player creature, or null while there is none (e.g. before the level has loaded it).
static func find(asker: Node) -> Node2D:
	if not _is_still_the_player():
		_player = asker.get_tree().get_first_node_in_group(GROUP) as Node2D
	return _player as Node2D


## One of the player's child components by node name (e.g. "Health"), or null.
static func find_component(asker: Node, component_name: String) -> Node:
	var player := find(asker)
	if player == null:
		return null
	return player.get_node_or_null(component_name)


static func _is_still_the_player() -> bool:
	if not is_instance_valid(_player):
		return false
	var player := _player as Node2D
	return player.is_inside_tree() and player.is_in_group(GROUP)
