class_name EmberTreeNodePainter
extends RefCounted
## Draws one Ember Tree node: skills and upgrades as diamond embers, stats as round coals,
## Ultimates as double diamonds, each with its icon, glow and padlock as its state asks.

const Kind := EmberTreeNode.Kind

## Size of one icon pixel; smaller frames get finer icons so they still fit.
const ICON_PIXEL := {Kind.SKILL: 3.0, Kind.UPGRADE: 2.5, Kind.STAT: 2.0, Kind.ULTIMATE: 3.0}
const EDGE_WIDTH := 2.5
## Gap between a node and the ring drawn around it when it, or its branch, is pointed at.
const HIGHLIGHT_GAP := 6.0
const LOCK_BADGE_RADIUS := 8.0


## Draws `node` at `centre`, grown by `hover`. `time` drives the pulse and flicker.
## `highlight` is the colour of the ring around it while it or its branch is pointed at
## (fully see-through for none).
static func draw_node(canvas: CanvasItem, node: EmberTreeNode, centre: Vector2, hover: float, time: float, highlight: Color) -> void:
	var state := EmberTreeNodeState.of(node)
	var radius: float = EmberTreeLayout.NODE_RADIUS[node.kind] * hover

	if state == EmberTreeNodeState.LEARNED:
		_draw_halo(canvas, centre, radius, time)
	if highlight.a > 0.0:
		_draw_outline_shape(canvas, node.kind, centre, radius + HIGHLIGHT_GAP, highlight)

	var fill: Color = EmberTreePalette.NODE_FILL[state]
	var edge: Color = EmberTreePalette.NODE_EDGE[state]
	if state == EmberTreeNodeState.AVAILABLE:
		edge = Color(edge, 0.55 + 0.45 * sin(time * 4.0))  # gentle pulse: "you can take this"
	_draw_body(canvas, node.kind, centre, radius, fill, edge)

	EmberTreeIcons.draw(canvas, node.icon, centre, ICON_PIXEL[node.kind] * hover, EmberTreePalette.NODE_ICON[state])
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
		draw_diamond(canvas, centre, radius - outline_width * 2.0, Color(edge, 0.5), false)


## A small padlock on a node whose ring opens only when Emberoo evolves.
static func _draw_lock_badge(canvas: CanvasItem, centre: Vector2) -> void:
	canvas.draw_circle(centre, LOCK_BADGE_RADIUS + 2.0, EmberTreePalette.OUTLINE)
	canvas.draw_circle(centre, LOCK_BADGE_RADIUS, EmberTreePalette.COAL)
	canvas.draw_arc(centre, LOCK_BADGE_RADIUS, 0.0, TAU, 24, EmberTreePalette.DIM, 1.5)
	EmberTreeIcons.draw(canvas, "lock", centre, 1.5, EmberTreePalette.GREY)


## A thin ring around a node in its own shape: a circle for stats, a diamond for the rest.
static func _draw_outline_shape(canvas: CanvasItem, kind: Kind, centre: Vector2, radius: float, color: Color) -> void:
	if kind == Kind.STAT:
		canvas.draw_arc(centre, radius, 0.0, TAU, 48, color, 2.0)
	else:
		draw_diamond(canvas, centre, radius * 1.1, color, false)


static func _draw_halo(canvas: CanvasItem, centre: Vector2, radius: float, time: float) -> void:
	var flicker := 0.85 + 0.15 * sin(time * 5.0 + centre.x)
	for halo: Array in [[18.0, 0.07], [11.0, 0.12], [5.0, 0.2]]:
		canvas.draw_circle(centre, radius + halo[0], Color(EmberTreePalette.ORANGE, halo[1] * flicker))
