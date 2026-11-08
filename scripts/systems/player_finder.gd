class_name PlayerFinder
extends RefCounted
## Finds the player creature (the one node in the "player" group) and its components,
## so nothing else needs to know how the player is found.

const GROUP := "player"


## The player creature, or null while there is none (e.g. before the level has loaded it).
static func find(asker: Node) -> Node2D:
	return asker.get_tree().get_first_node_in_group(GROUP) as Node2D


## One of the player's child components by node name (e.g. "Health"), or null.
static func find_component(asker: Node, component_name: String) -> Node:
	var player := find(asker)
	if player == null:
		return null
	return player.get_node_or_null(component_name)
