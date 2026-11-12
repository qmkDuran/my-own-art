class_name TerrainShape
extends RefCounted
## The woods' ground as a pure height function: gentle hills, one ridge (the high ground), one ravine and a rim that
## rises toward the tree line. The mesh, the props, the tests and the AI all read the same numbers from here.

const NORMAL_PROBE: float = 0.5
const HILL_PHASE_SKEW: float = 0.7

var _hills: Array = []
var _ridge_from: Vector2
var _ridge_to: Vector2
var _ridge_height: float
var _ridge_width: float
var _ravine: PackedVector2Array = PackedVector2Array()
var _ravine_depth: float
var _ravine_width: float
var _rim_start: float
var _rim_end: float
var _rim_height: float


func _init(spec: Dictionary) -> void:
	_hills = spec["hills"]
	var ridge: Dictionary = spec["ridge"]
	_ridge_from = Tuning.vec2(ridge["from"])
	_ridge_to = Tuning.vec2(ridge["to"])
	_ridge_height = float(ridge["height"])
	_ridge_width = float(ridge["width"])
	var ravine: Dictionary = spec["ravine"]
	for point: Array in ravine["points"]:
		_ravine.append(Tuning.vec2(point))
	_ravine_depth = float(ravine["depth"])
	_ravine_width = float(ravine["width"])
	var rim: Dictionary = spec["rim"]
	_rim_start = float(rim["start"])
	_rim_end = float(rim["end"])
	_rim_height = float(rim["height"])


func height(x: float, z: float) -> float:
	var p := Vector2(x, z)
	return _hill_height(p) + ridge_lift(p) - _ravine_cut(p) + _rim_lift(p)


func normal(x: float, z: float) -> Vector3:
	var dx: float = height(x + NORMAL_PROBE, z) - height(x - NORMAL_PROBE, z)
	var dz: float = height(x, z + NORMAL_PROBE) - height(x, z - NORMAL_PROBE)
	return Vector3(-dx, 2.0 * NORMAL_PROBE, -dz).normalized()


## How much the ridge raises this spot (0 away from it): used for high-ground colouring and the crest rule.
func ridge_lift(p: Vector2) -> float:
	var d: float = _segment_distance(p, _ridge_from, _ridge_to)
	return _ridge_height * exp(-d * d / (2.0 * _ridge_width * _ridge_width))


func ravine_distance(p: Vector2) -> float:
	var best: float = INF
	for k: int in _ravine.size() - 1:
		best = minf(best, _segment_distance(p, _ravine[k], _ravine[k + 1]))
	return best


func ridge_distance(p: Vector2) -> float:
	return _segment_distance(p, _ridge_from, _ridge_to)


func _hill_height(p: Vector2) -> float:
	var total: float = 0.0
	for hill: Array in _hills:
		var phase: float = float(hill[3])
		var wave: float = sin(p.x * float(hill[1]) + phase) * cos(p.y * float(hill[2]) + phase * HILL_PHASE_SKEW)
		total += float(hill[0]) * wave
	return total


func _ravine_cut(p: Vector2) -> float:
	var d: float = ravine_distance(p)
	return _ravine_depth * exp(-d * d / (2.0 * _ravine_width * _ravine_width))


func _rim_lift(p: Vector2) -> float:
	var edge: float = maxf(absf(p.x), absf(p.y))
	return _rim_height * smoothstep(_rim_start, _rim_end, edge)


static func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)
