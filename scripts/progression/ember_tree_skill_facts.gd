class_name EmberTreeSkillFacts
extends RefCounted
## Fills a skill node's facts with the real numbers of the skill as the player has it,
## so the tree never repeats (and never drifts from) the skill's own values.
##
## A node's `facts` may hold "{name}" placeholders. Each is filled from the player's node
## named by the node's `skill_action`: a SkillBar child (e.g. FlameUppercut: damage, reach,
## arc_degrees, plus its Skill resource's heat_cost and cooldown) or, failing that, a
## direct child of the player (e.g. SpinningHook, the jab combo's finisher).

const SKILL_BAR := SkillBar.NODE_NAME


## The node's facts with every placeholder filled in. Nodes without a skill come back as
## written; a skill the player doesn't have (yet) comes back as "" so no "{damage}" shows.
static func text_for(node: EmberTreeNode, player: Node) -> String:
	if node.skill_action == "":
		return node.facts
	var action := _find_action(node.skill_action, player)
	if action == null:
		return ""
	var values := _script_values(action)
	if action is SkillAction and (action as SkillAction).skill != null:
		values.merge(_script_values((action as SkillAction).skill))
	return node.facts.format(values)


static func _find_action(action_name: String, player: Node) -> Node:
	if player == null or not is_instance_valid(player):
		return null
	var skill_bar_action := player.get_node_or_null("%s/%s" % [SKILL_BAR, action_name])
	return skill_bar_action if skill_bar_action != null else player.get_node_or_null(action_name)


## Every number the object's script declares, by name, written as the screen shows it.
static func _script_values(object: Object) -> Dictionary:
	var values := {}
	for property in object.get_property_list():
		if not property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		var property_value: Variant = object.get(property["name"])
		if property_value is int or property_value is float:
			values[property["name"]] = number_text(property_value)
	return values


## 3 -> "3", 2.0 -> "2", 0.45 -> "0.45".
static func number_text(number: float) -> String:
	if is_equal_approx(number, roundf(number)):
		return str(roundi(number))
	return String.num(number, 2)
