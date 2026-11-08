class_name EmberTreeFactText
extends RefCounted
## What a node does in exact numbers, as rich text for the Ember Tree's info card.
##
## Stat nodes: one line per stat, worked out live from the player, e.g.
## "Max Health 10 → 12" with the new number coloured. Skills and other nodes: their facts
## (with a skill's real numbers filled in, see EmberTreeSkillFacts).


## Rich text (BBCode) for `node`. The new number is green while the node can still be
## learned and gold once it is. Empty if there is nothing exact to say.
static func for_node(node: EmberTreeNode, player: Node) -> String:
	if node.stat_changes.is_empty():
		return escape(EmberTreeSkillFacts.text_for(node, player))
	var after_color := EmberTreePalette.GOLD if EmberTree.is_learned(node.id) else EmberTreePalette.BETTER
	var lines := PackedStringArray()
	for change in EmberTreeStatSheet.new(player).changes_from(node):
		lines.append(change_bbcode(change["stat"], change["before"], change["after"], after_color, true))
	return "\n".join(lines)


## "Run speed 60 → 72 px/s (+20%)" with "→ 72 px/s" in `after_color`.
## Without `with_label`, just the numbers ("60 → 72 px/s"), for the stats panel.
static func change_bbcode(stat: String, before: float, after: float, after_color: Color, with_label: bool) -> String:
	var full := EmberTreeStatSheet.change_line(stat, before, after) if with_label else EmberTreeStatSheet.change_text(stat, before, after)
	var arrow_at := full.find(EmberTreeStatSheet.ARROW)
	var after_part := full.substr(arrow_at)
	return "%s%s" % [escape(full.substr(0, arrow_at)), colored(after_part, after_color)]


static func colored(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), escape(text)]


## Keeps square brackets in plain text from being read as BBCode tags.
static func escape(text: String) -> String:
	return text.replace("[", "[lb]")
