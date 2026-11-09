extends Node
## Which Ember Tree nodes the player has learned (registered as the "EmberTree" autoload).
##
## Holds the rules: a node can be learned when its stage is open, a node leading to it
## is learned (or it grows from the centre) and there is a skill point to spend.
## Respec is free: unlearning gives the point back. Kept in an autoload so it survives
## the level restarting; EmberTreeEffects listens to `changed` to apply stat nodes, and
## skills ask `is_skill_unlocked` each time they would fire, so unlearning takes them away.

signal changed

## Stage 1 is open from the start; later rings open as Emberoo Awakens.
const FIRST_STAGE := AwakeningStage.FIRST_TREE_STAGE

## The outermost ring open. Set by the Awakening autoload (Awakening I opens Stage 2).
var unlocked_stage: int = FIRST_STAGE

var _learned: Dictionary[String, bool] = {}


func is_learned(id: String) -> bool:
	return _learned.has(id)


## Whether the player's skill node named `action_name` (e.g. "FlameUppercut") may be used:
## its Ember Tree skill node is learned. Actions no skill node names are always usable.
func is_skill_unlocked(action_name: String) -> bool:
	var node := EmberTreeData.skill_node_for(action_name)
	return node == null or is_learned(node.id)


func learned_ids() -> Array[String]:
	return _learned.keys()


func is_stage_open(stage: int) -> bool:
	return stage <= unlocked_stage


## Opens (or closes) the rings up to `stage`. Closing a ring (only DebugControls' F4 does)
## puts out the nodes learned in it and refunds their points.
func set_unlocked_stage(stage: int) -> void:
	stage = maxi(FIRST_STAGE, stage)
	if stage == unlocked_stage:
		return
	unlocked_stage = stage
	for id in learned_ids():
		if not is_stage_open(EmberTreeData.find(id).stage):
			_learned.erase(id)
			Progression.refund_skill_point()
	changed.emit()


## True when the node's stage is open and a path leads to it, whether or not a point is free.
func is_reachable(id: String) -> bool:
	var node := EmberTreeData.find(id)
	if node == null or not is_stage_open(node.stage):
		return false
	if node.requires.is_empty():
		return true
	for required_id in node.requires:
		if is_learned(required_id):
			return true
	return false


func can_learn(id: String) -> bool:
	return not is_learned(id) and is_reachable(id) and Progression.skill_points > 0


## Learns a node, spending one skill point. Returns false if it can't be learned.
func learn(id: String) -> bool:
	if not _learn_silently(id):
		return false
	changed.emit()
	return true


## A node can be put out only if nothing learned would be left cut off from the centre.
func can_unlearn(id: String) -> bool:
	if not is_learned(id):
		return false
	for dependent_id in _learned_nodes_that_need(id):
		if not _has_other_learned_path(dependent_id, id):
			return false
	return true


## Unlearns a node and refunds its point (free respec). Returns false if it can't.
func unlearn(id: String) -> bool:
	if not can_unlearn(id):
		return false
	_learned.erase(id)
	Progression.refund_skill_point()
	changed.emit()
	return true


## Unlearns everything and refunds every point.
func reset() -> void:
	if _learned.is_empty():
		return
	for _id in _learned:
		Progression.refund_skill_point()
	_learned.clear()
	changed.emit()


## What SaveGame writes: just the learned node IDs, so nodes added to the tree later need no
## migration. The open rings follow from the Awakening stage, which is saved on its own.
func to_save_data() -> Dictionary:
	return {"learned": learned_ids()}


## Restores a save (an empty one means nothing learned). Load Progression and Awakening
## (which opens the rings) first: every saved node is learned again under the usual rules,
## spending a point each, so unknown IDs, nodes with no path to them, nodes in a ring that
## isn't open and nodes beyond the points owned are simply dropped.
func load_save_data(data: Dictionary) -> void:
	_learned.clear()
	var waiting := SaveData.read_strings(data, "learned")
	# A node can only be learned once a node leading to it is, so pass over the list until nothing more fits.
	var learned_any := true
	while learned_any:
		learned_any = false
		for id: String in waiting.duplicate():
			if _learn_silently(id):
				waiting.erase(id)
				learned_any = true
	for id in waiting:
		push_warning("Ember Tree: dropped saved node '%s' (unknown, unreachable or no point left)." % id)
	changed.emit()


func _learn_silently(id: String) -> bool:
	if not can_learn(id) or not Progression.spend_skill_point():
		return false
	_learned[id] = true
	return true


func _learned_nodes_that_need(id: String) -> Array[String]:
	var dependents: Array[String] = []
	for learned_id in _learned:
		if EmberTreeData.find(learned_id).requires.has(id):
			dependents.append(learned_id)
	return dependents


## Whether `id` still has a learned node leading to it once `removed_id` is gone.
## Every learned node is itself connected, so checking one step back is enough.
func _has_other_learned_path(id: String, removed_id: String) -> bool:
	for required_id in EmberTreeData.find(id).requires:
		if required_id != removed_id and is_learned(required_id):
			return true
	return false
