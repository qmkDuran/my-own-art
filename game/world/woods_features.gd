class_name WoodsFeatures
extends RefCounted
## The parts of the woods that moves interact with, read from data/woods.json: soft soil you can burrow in (rocky
## patches you cannot), the stream and pond you can wade and dive in, the marked trees you can climb, and jump spots
## (a launch point and a landing on a rock, log or ledge).

var climbable: Array[Vector3] = []
var _soft: Array[Dictionary] = []
var _rocky: Array[Dictionary] = []
var _pond: Dictionary = {}
var _stream: PackedVector2Array = PackedVector2Array()
var _stream_width: float = 0.0
var _jumps: Array[Dictionary] = []


func _init(layout: Dictionary, ground: Callable) -> void:
	for patch: Dictionary in layout.get("soft_ground", []):
		_soft.append({ "pos": Tuning.vec2(patch["pos"]), "radius": float(patch["radius"]) })
	for patch: Dictionary in layout.get("rocky_ground", []):
		_rocky.append({ "pos": Tuning.vec2(patch["pos"]), "radius": float(patch["radius"]) })
	_pond = layout.get("pond", {})
	var stream: Dictionary = layout.get("stream", {})
	for point: Array in stream.get("points", []):
		_stream.append(Tuning.vec2(point))
	_stream_width = float(stream.get("width", 0.0))
	for jump: Dictionary in layout.get("jump_spots", []):
		_jumps.append({ "from": ground.call(Tuning.vec2(jump["from"])), "to": ground.call(Tuning.vec2(jump["to"])) })


func soft_at(point: Vector3) -> bool:
	var p := Vector2(point.x, point.z)
	return _inside_any(p, _soft) and not _inside_any(p, _rocky)


func rocky_at(point: Vector3) -> bool:
	return _inside_any(Vector2(point.x, point.z), _rocky)


func water_at(point: Vector3) -> bool:
	var p := Vector2(point.x, point.z)
	if not _pond.is_empty() and p.distance_to(Tuning.vec2(_pond["pos"])) <= float(_pond["radius"]):
		return true
	for k: int in _stream.size() - 1:
		if TerrainShape.segment_distance(p, _stream[k], _stream[k + 1]) <= _stream_width * 0.5:
			return true
	return false


## The nearest point of soft soil to `point` within `reach` (its patch centre), or Vector3.INF.
func soft_centre_near(point: Vector3, reach: float) -> Vector2:
	var best: Vector2 = Vector2.INF
	for patch: Dictionary in _soft:
		var centre: Vector2 = patch["pos"]
		var d: float = centre.distance_to(Vector2(point.x, point.z))
		var nearer: bool = best == Vector2.INF or d < best.distance_to(Vector2(point.x, point.z))
		if d <= reach + float(patch["radius"]) and nearer:
			best = centre
	return best


## The trunk of the nearest climbable tree within reach of `point`, or Vector3.INF.
func climbable_near(point: Vector3, reach: float) -> Vector3:
	var best: Vector3 = Vector3.INF
	for trunk: Vector3 in climbable:
		var d: float = Vector2(trunk.x - point.x, trunk.z - point.z).length()
		if d <= reach and (best == Vector3.INF or d < Vector2(best.x - point.x, best.z - point.z).length()):
			best = trunk
	return best


## Jump spots whose launch point is within reach, nearest first.
func jump_spots_near(point: Vector3, reach: float) -> Array[Dictionary]:
	var near: Array[Dictionary] = _jumps.filter(func(jump: Dictionary) -> bool:
		return (jump["from"] as Vector3).distance_to(point) <= reach)
	near.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["from"] as Vector3).distance_to(point) < (b["from"] as Vector3).distance_to(point))
	return near


func jump_spots() -> Array[Dictionary]:
	return _jumps


func rocky_patches() -> Array[Dictionary]:
	return _rocky


static func _inside_any(p: Vector2, patches: Array[Dictionary]) -> bool:
	for patch: Dictionary in patches:
		if p.distance_to(patch["pos"]) <= float(patch["radius"]):
			return true
	return false
