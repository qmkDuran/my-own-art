class_name EmberTreeLayout
extends RefCounted
## Where everything sits in the Ember Tree, in "tree space" (Emberoo at (0, 0)).
##
## Shared by the canvas that draws the tree and the screen that picks the opening zoom.

const Kind := EmberTreeNode.Kind

## Distance from Emberoo for each tier, in tree pixels. Tiers 0-2 = Stage 1, 3 = Stage 2, 4 = Stage 3.
## Rings sit 90 apart (130 around the branch names), so even two glowing, pointed-at
## neighbours keep clear of each other (see `node_reach`).
const TIER_RADII: Array[float] = [110.0, 200.0, 290.0, 420.0, 520.0]
## Branch names sit in the gap between the Stage 1 and Stage 2 rings.
const BRANCH_LABEL_RADIUS := 355.0
const BRANCH_LABEL_SIZE := EmberTreeFonts.LARGE_SIZE
## Room around a branch name that still counts as pointing at it, and that its hover pill fills.
const BRANCH_LABEL_PADDING := Vector2(8.0, 5.0)
const CENTRE_RADIUS := 46.0
## The id the veins use for Emberoo in the middle.
const CENTRE_ID := "centre"
const NODE_RADIUS := {Kind.SKILL: 24.0, Kind.UPGRADE: 21.0, Kind.STAT: 18.0, Kind.ULTIMATE: 28.0}
## Dark rim drawn outside every node so it stands off the veins behind it.
const OUTLINE_WIDTH := 3.0
## How much bigger a node grows while pointed at.
const HOVER_SCALE := 1.15
## How far a learned node's glow reaches past its edge (see EmberTreeNodePainter).
const HALO_REACH := 18.0
## Gap between a node and the ring drawn around it when it, or its branch, is pointed at.
const HIGHLIGHT_GAP := 6.0
## Diamonds' highlight rings sit a little wider, so they clear the diamond's corners.
const DIAMOND_HIGHLIGHT_WIDEN := 1.1


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
	var font := EmberTreeFonts.smooth()
	var text_width := font.get_string_size(branch_label_text(branch), HORIZONTAL_ALIGNMENT_LEFT, -1, BRANCH_LABEL_SIZE).x
	var text_size := Vector2(text_width, BRANCH_LABEL_SIZE * EmberTreeFonts.CAP_HEIGHT_RATIO)
	var middle := branch_label_middle(branch)
	return Rect2(middle - text_size / 2.0, text_size).grow_individual(
		BRANCH_LABEL_PADDING.x, BRANCH_LABEL_PADDING.y, BRANCH_LABEL_PADDING.x, BRANCH_LABEL_PADDING.y)


## What must be on screen when the tree opens: every Stage 1 node (at hover size) and
## every branch name. Later rings may spill past the edges.
static func opening_bounds() -> Rect2:
	var bounds := Rect2(-Vector2.ONE * CENTRE_RADIUS, Vector2.ONE * CENTRE_RADIUS * 2.0)
	for node in EmberTreeData.all_nodes():
		if node.stage == EmberTree.FIRST_STAGE:
			var reach := node_reach(node)
			bounds = bounds.merge(Rect2(node_position(node) - Vector2.ONE * reach, Vector2.ONE * reach * 2.0))
	for branch: String in EmberTreeData.BRANCHES:
		bounds = bounds.merge(branch_label_rect(branch))
	return bounds


## How far anything drawn for a node can reach from its centre: its glow, or its
## pointed-at size with the highlight ring, whichever is bigger.
static func node_reach(node: EmberTreeNode) -> float:
	var radius: float = NODE_RADIUS[node.kind]
	var highlight := (radius * HOVER_SCALE + HIGHLIGHT_GAP) * DIAMOND_HIGHLIGHT_WIDEN
	return maxf(radius + HALO_REACH, highlight + OUTLINE_WIDTH)


## The evolution stage a tier belongs to (0 for a tier before the first, so it never matches).
static func stage_of_tier(tier: int) -> int:
	if tier < 0:
		return 0
	for node in EmberTreeData.all_nodes():
		if node.tier == tier:
			return node.stage
	return EmberTree.FIRST_STAGE
