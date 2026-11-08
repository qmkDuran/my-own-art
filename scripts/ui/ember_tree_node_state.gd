class_name EmberTreeNodeState
extends RefCounted
## Where an Ember Tree node stands for the player right now, as the screen shows it.

## Ignited.
const LEARNED := "learned"
## Can be ignited now.
const AVAILABLE := "available"
## Needs a node leading to it, or a skill point, first.
const LOCKED := "locked"
## Its ring opens only when Emberoo evolves.
const SEALED := "sealed"


static func of(node: EmberTreeNode) -> String:
	if EmberTree.is_learned(node.id):
		return LEARNED
	if EmberTree.can_learn(node.id):
		return AVAILABLE
	if not EmberTree.is_stage_open(node.stage):
		return SEALED
	return LOCKED
