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
## What changes in play when this is learned. Behaviour, not small percentages.
@export_multiline var description: String = ""
## Ids of nodes that lead here; learning any one of them is enough. Empty = grows from the centre.
@export var requires: PackedStringArray = PackedStringArray()
## Stat changes this node makes, e.g. {"max_health": 2} (see EmberTreeEffects).
## Empty means the effect is still being built, and the tooltip says "coming soon".
@export var stat_changes: Dictionary = {}


func has_working_effect() -> bool:
	return not stat_changes.is_empty()


func is_stat() -> bool:
	return kind == Kind.STAT


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
	node.requires = PackedStringArray(row.get("requires", []))
	node.stat_changes = row.get("stats", {})
	return node
