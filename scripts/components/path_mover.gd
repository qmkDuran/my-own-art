class_name PathMover
extends NavigationAgent2D
## Pathfinding for a walking body (its parent): which way to step next to reach a target,
## around walls, ruins, rocks and trees, along the zone's navmesh (see ZoneNavigation).
##
## The path is worked out again every `repath_interval` seconds, not every frame, and each
## mover starts at a random point in that cycle, so a crowd doesn't repath on the same frame.
## Between repaths the body follows the path it has; once at its end, it walks the last
## stretch straight. Without a navmesh (e.g. the open test arena) or a path to follow, it
## simply goes in a straight line.
##
## Backing away (direction_away_from) doesn't use the navmesh: it turns aside from walls
## by checking the body's own collision, so it also works where there is no navmesh.

## Turns tried, in order, when the straight way back is blocked: away, then angled, then sideways.
const RETREAT_TURNS_DEGREES: Array[float] = [0.0, 45.0, -45.0, 90.0, -90.0]
## A path point this close to the body counts as reached, in pixels.
const WAYPOINT_REACHED_DISTANCE := 4.0

## Seconds between path updates.
@export var repath_interval: float = 0.25
## When backing away, how far ahead to check for walls, in pixels.
@export var retreat_lookahead: float = 12.0

var _seconds_until_repath: float = 0.0
## Whether the latest repath found a navmesh to follow.
var _is_following_path: bool = false

@onready var _body: CharacterBody2D = get_parent()


func _ready() -> void:
	path_desired_distance = WAYPOINT_REACHED_DISTANCE
	target_desired_distance = WAYPOINT_REACHED_DISTANCE
	_seconds_until_repath = randf() * repath_interval


func _physics_process(delta: float) -> void:
	_seconds_until_repath -= delta


## The direction to walk this frame to reach `target` (unit length, or zero when on it).
func direction_toward(target: Vector2) -> Vector2:
	if _seconds_until_repath <= 0.0:
		_repath(target)
	if _is_following_path and not is_navigation_finished():
		var to_waypoint := get_next_path_position() - _body.global_position
		if to_waypoint.length() > 0.5:
			return to_waypoint.normalized()
	return _body.global_position.direction_to(target)


## How far the body still has to walk to `target`: along the path when following one,
## otherwise straight. Call after direction_toward for the same target.
func distance_to(target: Vector2) -> float:
	if not _is_following_path or is_navigation_finished():
		return _body.global_position.distance_to(target)
	var path := get_current_navigation_path()
	var distance := 0.0
	var from := _body.global_position
	for index in range(get_current_navigation_path_index(), path.size()):
		distance += from.distance_to(path[index])
		from = path[index]
	return distance + from.distance_to(target)


## Works the path out again on the next direction_toward (e.g. the player clicked a new spot).
func repath_now() -> void:
	_seconds_until_repath = 0.0


## The nearest walkable spot to `point`, so a body asked to walk into a wall stops in front of
## it. Spots within the navmesh's margin stay as they are (the body fits there).
func nearest_reachable_point(point: Vector2) -> Vector2:
	if not _has_navmesh():
		return point
	var closest := NavigationServer2D.map_get_closest_point(get_navigation_map(), point)
	if closest.distance_to(point) <= ZoneNavigation.AGENT_RADIUS + WAYPOINT_REACHED_DISTANCE:
		return point
	return closest


## A direction away from `threat` that isn't straight into a wall: the first free one of
## straight away, angled away, or sideways. Zero when every way is blocked (pinned).
func direction_away_from(threat: Vector2) -> Vector2:
	var away := threat.direction_to(_body.global_position)
	if away == Vector2.ZERO:
		return Vector2.ZERO
	for turn in RETREAT_TURNS_DEGREES:
		var candidate := away.rotated(deg_to_rad(turn))
		if not _body.test_move(_body.global_transform, candidate * retreat_lookahead):
			return candidate
	return Vector2.ZERO


func _repath(target: Vector2) -> void:
	_seconds_until_repath = repath_interval
	_is_following_path = _has_navmesh()
	if _is_following_path:
		target_position = target


func _has_navmesh() -> bool:
	return not NavigationServer2D.map_get_regions(get_navigation_map()).is_empty()
