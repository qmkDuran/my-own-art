class_name EmberTreeNode
extends Resource
## One node of the Ember Tree: a skill, an upgrade to a skill, a stat pick or an Ultimate.
##
## Pure data: what the node is called, where it sits and what it needs.
## The rules (can it be learned?) live in the EmberTree autoload; the look lives in the UI.

enum Kind { SKILL, UPGRADE, STAT, ULTIMATE }

## Unique, never shown to the player; learned state is stored by this id.
@export var id: String = ""
## Which branch it belongs to (see EmberTreeData.BRANCHES).
@export var branch: String = ""
## Evolution stage that opens it: 1 = inner ring, 2 = middle ring, 3 = outer ring.
@export var stage: int = 1
## Steps out from the centre, counted across every ring (0 = closest to Emberoo).
@export var tier: int = 0
## Degrees away from its branch's direction, so siblings fan out side by side.
@export var angle_offset: float = 0.0
@export var kind: Kind = Kind.SKILL
## Name of the pixel icon drawn on the node (see EmberTreeIcons).
@export var icon: String = ""
@export var title: String = ""
## One short flavour clause, e.g. "Heavier fists." The exact effect lives in `facts` or
## `stat_changes`, never here.
@export_multiline var description: String = ""
## The exact effect in plain words and real numbers, for nodes without `stat_changes`
## (those get theirs worked out live, see EmberTreeStatSheet). With `skill_action` set,
## "{name}" placeholders are filled from that skill's real values (see EmberTreeSkillFacts).
@export_multiline var facts: String = ""
## Name of the player's node that plays this skill, a SkillBar child (e.g. "FlameUppercut")
## or a direct child (e.g. "SpinningHook"), whose numbers fill `facts`.
## Empty for nodes that aren't a built skill.
@export var skill_action: String = ""
## Ids of nodes that lead here; learning any one of them is enough. Empty = grows from the centre.
@export var requires: PackedStringArray = PackedStringArray()
## Stat changes this node makes, e.g. {"max_health": 2} (see EmberTreeEffects).
## Empty (with no `skill_action`) means the effect is still being built, and the screen
## says "coming soon".
@export var stat_changes: Dictionary = {}


func has_working_effect() -> bool:
	return not stat_changes.is_empty() or skill_action != ""


## Builds a node from one row of EmberTreeData's table.
static func from_row(row: Dictionary) -> EmberTreeNode:
	var node := EmberTreeNode.new()
	node.id = row["id"]
	node.branch = row["branch"]
	node.stage = row["stage"]
	node.tier = row["tier"]
	node.angle_offset = row.get("angle", 0.0)
	node.kind = row["kind"]
	node.icon = row["icon"]
	node.title = row["title"]
	node.description = row["text"]
	node.facts = row.get("facts", "")
	node.skill_action = row.get("skill_action", "")
	node.requires = PackedStringArray(row.get("requires", []))
	node.stat_changes = row.get("stats", {})
	return node
