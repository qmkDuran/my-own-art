class_name EmberTreeLayout
extends RefCounted
## Where everything sits in the Ember Tree, in "tree space" (Emberoo at (0, 0)).
##
## Shared by the canvas that draws the tree and the screen that picks the opening zoom.

const Kind := EmberTreeNode.Kind

## Distance from Emberoo for each tier, in tree pixels. Tiers 0-2 = Stage 1, 3 = Stage 2, 4 = Stage 3.
const TIER_RADII: Array[float] = [92.0, 142.0, 192.0, 266.0, 336.0]
## Branch names sit in the gap between the Stage 1 and Stage 2 rings.
const BRANCH_LABEL_RADIUS := 238.0
const BRANCH_LABEL_SIZE := 18
## Room around a branch name that still counts as pointing at it, and that its hover pill fills.
const BRANCH_LABEL_PADDING := Vector2(8.0, 5.0)
## Capital letters are about this tall for each pixel of font size; used to centre words on a spot.
const CAP_HEIGHT_RATIO := 0.72
const CENTRE_RADIUS := 46.0
## The id the veins use for Emberoo in the middle.
const CENTRE_ID := "centre"
const NODE_RADIUS := {Kind.SKILL: 24.0, Kind.UPGRADE: 21.0, Kind.STAT: 18.0, Kind.ULTIMATE: 28.0}
## Dark rim drawn outside every node so it stands off the veins behind it.
const OUTLINE_WIDTH := 3.0
## How much bigger a node grows while pointed at.
const HOVER_SCALE := 1.15


## Where a node sits: out along its branch, one ring per tier.
static func node_position(node: EmberTreeNode) -> Vector2:
	var angle := EmberTreeData.branch_angle(node.branch) + node.angle_offset
	return Vector2.from_angle(deg_to_rad(angle)) * TIER_RADII[node.tier]


## The words shown for a branch, e.g. "INFERNO".
static func branch_label_text(branch: String) -> String:
	return EmberTreeData.branch_title(branch).to_upper()


## The middle of a branch's name.
static func branch_label_middle(branch: String) -> Vector2:
	return Vector2.from_angle(deg_to_rad(EmberTreeData.branch_angle(branch))) * BRANCH_LABEL_RADIUS


## The box around a branch's name, padding included (what hovering hits).
static func branch_label_rect(branch: String) -> Rect2:
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(branch_label_text(branch), HORIZONTAL_ALIGNMENT_LEFT, -1, BRANCH_LABEL_SIZE).x
	var text_size := Vector2(text_width, BRANCH_LABEL_SIZE * CAP_HEIGHT_RATIO)
	var middle := branch_label_middle(branch)
	return Rect2(middle - text_size / 2.0, text_size).grow_individual(
		BRANCH_LABEL_PADDING.x, BRANCH_LABEL_PADDING.y, BRANCH_LABEL_PADDING.x, BRANCH_LABEL_PADDING.y)


## What must be on screen when the tree opens: every Stage 1 node (at hover size) and
## every branch name. Later rings may spill past the edges.
static func opening_bounds() -> Rect2:
	var bounds := Rect2(-Vector2.ONE * CENTRE_RADIUS, Vector2.ONE * CENTRE_RADIUS * 2.0)
	for node in EmberTreeData.all_nodes():
		if node.stage == EmberTree.FIRST_STAGE:
			var reach: float = NODE_RADIUS[node.kind] * HOVER_SCALE + OUTLINE_WIDTH
			bounds = bounds.merge(Rect2(node_position(node) - Vector2.ONE * reach, Vector2.ONE * reach * 2.0))
	for branch: String in EmberTreeData.BRANCHES:
		bounds = bounds.merge(branch_label_rect(branch))
	return bounds


## The evolution stage a tier belongs to (0 for a tier before the first, so it never matches).
static func stage_of_tier(tier: int) -> int:
	if tier < 0:
		return 0
	for node in EmberTreeData.all_nodes():
		if node.tier == tier:
			return node.stage
	return EmberTree.FIRST_STAGE
