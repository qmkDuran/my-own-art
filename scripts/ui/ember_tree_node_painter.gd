class_name EmberTreeNodePainter
extends RefCounted
## Draws one Ember Tree node: skills and upgrades as diamond embers, stats as round coals,
## Ultimates as double diamonds, each with its icon, glow and padlock as its state asks.

const Kind := EmberTreeNode.Kind

## States whose icon is shown greyed, as the HUD greys a skill that can't be used yet.
const GREYED_ICON_STATES := [EmberTreeNodeState.LOCKED, EmberTreeNodeState.SEALED]
const EDGE_WIDTH := 3.0
## An Ultimate's inner diamond, as a share of its radius; its icon fits inside that one.
const ULTIMATE_INNER_SHARE := 0.85
const LOCK_BADGE_RADIUS := 8.0
const LOCK_PIXEL := 1.5
## A learned node's glow: rings reaching this share of the full glow, each this opaque.
const HALO_LAYERS := [[1.0, 0.07], [0.6, 0.12], [0.28, 0.2]]


## Draws `node` at `tree_position` (snapped to a whole screen pixel, the same middle its
## icon uses), grown by `hover`. `time` drives the pulse and flicker.
## `highlight` is the colour of the ring around it while it or its branch is pointed at
## (fully see-through for none). The glow of a learned node is drawn separately, by
## `draw_halo`, underneath every node, so a glow never covers a neighbour.
static func draw_node(canvas: CanvasItem, node: EmberTreeNode, tree_position: Vector2, hover: float, time: float, highlight: Color) -> void:
	var state := EmberTreeNodeState.of(node)
	var radius: float = EmberTreeLayout.NODE_RADIUS[node.kind] * hover
	var centre := EmberTreeIcons.snapped_to_screen(canvas, tree_position)

	if highlight.a > 0.0:
		_draw_outline_shape(canvas, node.kind, centre, radius + EmberTreeLayout.highlight_gap(radius), highlight)

	var fill: Color = EmberTreePalette.NODE_FILL[state]
	var edge: Color = EmberTreePalette.NODE_EDGE[state]
	if state == EmberTreeNodeState.AVAILABLE:
		edge = Color(edge, 0.55 + 0.45 * sin(time * 4.0))  # gentle pulse: "you can take this"
	_draw_body(canvas, node.kind, centre, radius, fill, edge)

	EmberTreeIcons.draw(canvas, node.id, centre, _icon_room(node.kind, radius), node.kind == Kind.STAT,
		state in GREYED_ICON_STATES, EmberTreePalette.NODE_ICON_TINT[state])
	if state == EmberTreeNodeState.SEALED:
		_draw_lock_badge(canvas, centre + Vector2.ONE * radius * 0.6)


## A diamond standing on one corner, filled or as an outline `width` thick.
static func draw_diamond(canvas: CanvasItem, centre: Vector2, radius: float, color: Color, filled: bool, width: float = EDGE_WIDTH) -> void:
	var points := PackedVector2Array([
		centre + Vector2(0, -radius), centre + Vector2(radius, 0),
		centre + Vector2(0, radius), centre + Vector2(-radius, 0),
	])
	if filled:
		canvas.draw_colored_polygon(points, color)
	else:
		points.append(points[0])
		canvas.draw_polyline(points, color, width)


## The dark rim, the fill and the edge: a circle for stats, a diamond for the rest.
static func _draw_body(canvas: CanvasItem, kind: Kind, centre: Vector2, radius: float, fill: Color, edge: Color) -> void:
	var outline_width := EmberTreeLayout.OUTLINE_WIDTH
	if kind == Kind.STAT:
		canvas.draw_circle(centre, radius + outline_width, EmberTreePalette.OUTLINE)
		canvas.draw_circle(centre, radius, fill)
		canvas.draw_arc(centre, radius, 0.0, TAU, 48, edge, EDGE_WIDTH)
		return
	draw_diamond(canvas, centre, radius + outline_width, EmberTreePalette.OUTLINE, true)
	draw_diamond(canvas, centre, radius, fill, true)
	draw_diamond(canvas, centre, radius, edge, false)
	if kind == Kind.ULTIMATE:
		draw_diamond(canvas, centre, radius * ULTIMATE_INNER_SHARE, Color(edge, 0.5), false)


## The radius of the innermost line of a node's frame, which its icon must fit inside.
static func _icon_room(kind: Kind, radius: float) -> float:
	return radius * ULTIMATE_INNER_SHARE if kind == Kind.ULTIMATE else radius


## A small padlock on a node whose ring opens only when Emberoo Awakens.
static func _draw_lock_badge(canvas: CanvasItem, centre: Vector2) -> void:
	canvas.draw_circle(centre, LOCK_BADGE_RADIUS + 2.0, EmberTreePalette.OUTLINE)
	canvas.draw_circle(centre, LOCK_BADGE_RADIUS, EmberTreePalette.COAL)
	canvas.draw_arc(centre, LOCK_BADGE_RADIUS, 0.0, TAU, 24, EmberTreePalette.DIM, 1.5)
	EmberTreeIcons.draw_lock(canvas, centre, LOCK_PIXEL, EmberTreePalette.GREY)


## A thin ring around a node in its own shape: a circle for stats, a diamond for the rest.
static func _draw_outline_shape(canvas: CanvasItem, kind: Kind, centre: Vector2, radius: float, color: Color) -> void:
	if kind == Kind.STAT:
		canvas.draw_arc(centre, radius, 0.0, TAU, 48, color, 2.0)
	else:
		draw_diamond(canvas, centre, radius * EmberTreeLayout.DIAMOND_HIGHLIGHT_WIDEN, color, false)


## The flickering orange glow around a learned node, `hover` times its size.
static func draw_halo(canvas: CanvasItem, node: EmberTreeNode, tree_position: Vector2, hover: float, time: float) -> void:
	var radius: float = EmberTreeLayout.NODE_RADIUS[node.kind] * hover
	var centre := EmberTreeIcons.snapped_to_screen(canvas, tree_position)
	var reach := EmberTreeLayout.halo_reach(radius)
	var flicker := 0.85 + 0.15 * sin(time * 5.0 + tree_position.x)
	for halo: Array in HALO_LAYERS:
		canvas.draw_circle(centre, radius + reach * halo[0], Color(EmberTreePalette.ORANGE, halo[1] * flicker))
