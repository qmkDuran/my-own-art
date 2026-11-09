class_name ZoneNavigation
extends NavigationRegion2D
## The walkable space of a zone, for pathfinding (see PathMover).
##
## The navmesh is baked when the zone loads, from the collision of everything in the
## `navigation_obstacles` group: the Obstacles tile layer (walls, ruins, rocks, forest) and the
## arena gates. Baking from collision (rather than painting navigation polygons on the ground
## tiles) keeps one source of truth, the tiles' collision shapes, and lets Godot shrink the
## walkable space by an agent radius, so walkers keep clear of corners. Tile navigation
## polygons can't leave such a margin.
##
## A closed arena gate is an obstacle and an open one isn't (its collision is off then), so
## the gate asks for a rebake whenever it changes; the bake runs on a thread.

## Nodes (with their children) whose static collision is carved out of the navmesh.
const OBSTACLES_GROUP := "navigation_obstacles"
## Zone navigation regions are in this group, so gates can ask them to rebake.
const GROUP := "zone_navigation"
## How far walkers keep from obstacles, in pixels (about a creature's body radius).
const AGENT_RADIUS := 6.0
## Navmesh vertices snap to this grid, in pixels.
const CELL_SIZE := 1.0

## The ground layer: its painted area is the walkable outline before obstacles are carved out.
@export var ground: TileMapLayer

var _wants_another_bake: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	navigation_polygon = _empty_navigation_polygon()
	bake_finished.connect(_on_bake_finished)
	# Bake at once (not on a thread), so enemies can path from their very first step.
	bake_navigation_polygon(false)


## Bakes again (e.g. a gate opened or closed). Waits for the end of the frame, so collision
## changes made this frame are seen.
func rebake() -> void:
	_start_bake.call_deferred()


func _start_bake() -> void:
	# A deferred request can land after the zone has left the tree (e.g. it was swapped out).
	if not is_inside_tree():
		return
	if is_baking():
		_wants_another_bake = true
		return
	bake_navigation_polygon(true)


func _on_bake_finished() -> void:
	if _wants_another_bake:
		_wants_another_bake = false
		_start_bake()


func _empty_navigation_polygon() -> NavigationPolygon:
	var polygon := NavigationPolygon.new()
	polygon.cell_size = CELL_SIZE
	polygon.agent_radius = AGENT_RADIUS
	polygon.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	polygon.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	polygon.source_geometry_group_name = OBSTACLES_GROUP
	polygon.add_outline(_ground_outline())
	return polygon


## The corners of the ground's painted area, in this region's space.
func _ground_outline() -> PackedVector2Array:
	var cells := ground.get_used_rect()
	var tile_size := Vector2(ground.tile_set.tile_size)
	var top_left := to_local(ground.to_global(Vector2(cells.position) * tile_size))
	var bottom_right := to_local(ground.to_global(Vector2(cells.end) * tile_size))
	return PackedVector2Array([
		top_left,
		Vector2(bottom_right.x, top_left.y),
		bottom_right,
		Vector2(top_left.x, bottom_right.y),
	])
