class_name EmberTreeStatusText
extends RefCounted
## The one-line status the side panel shows under a node or a branch: where it stands now.


## Where a node stands: Ignited, Can ignite, Not enough points, Needs: <node>,
## or Locked until evolution. `state` is its EmberTreeNodeState.
static func for_node(node: EmberTreeNode, state: String) -> String:
	match state:
		EmberTreeNodeState.LEARNED:
			if EmberTree.can_unlearn(node.id):
				return "Ignited  ·  right-click to put out (free)"
			return "Ignited  ·  put out the embers beyond it first"
		EmberTreeNodeState.AVAILABLE:
			return "Can ignite  ·  click to spend 1 skill point"
		EmberTreeNodeState.SEALED:
			return "Locked  ·  unlocks when Emberoo evolves (Stage %d)" % node.stage
	if EmberTree.is_reachable(node.id):
		return "Not enough points  ·  earn 1 each level"
	return "Needs: %s" % _required_titles(node)


## How much of a branch is ignited, e.g. "2 of 5 ignited  ·  6 more after evolving".
static func for_branch(branch: String) -> String:
	var open := 0
	var sealed := 0
	for node in EmberTreeData.nodes_in_branch(branch):
		if EmberTree.is_stage_open(node.stage):
			open += 1
		else:
			sealed += 1
	var status := "%d of %d ignited" % [ignited_in_branch(branch), open]
	if sealed > 0:
		status += "  ·  %d more after evolving" % sealed
	return status


static func ignited_in_branch(branch: String) -> int:
	var ignited := 0
	for node in EmberTreeData.nodes_in_branch(branch):
		if EmberTree.is_learned(node.id):
			ignited += 1
	return ignited


## The names of the nodes that lead to this one, e.g. "Meteor Fist or Heat Sink".
static func _required_titles(node: EmberTreeNode) -> String:
	var titles := PackedStringArray()
	for required_id in node.requires:
		titles.append(EmberTreeData.find(required_id).title)
	return " or ".join(titles)
