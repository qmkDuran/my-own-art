class_name TerrainShape
extends RefCounted
## The woods' ground as a pure height function: gentle hills, one ridge (the high ground), one ravine (with the
## stream), a basin for the pond, a small cliff-edged plateau with one ramp, and a rim that rises toward the tree
## line. The mesh, the props, the water, the tests and the AI all read the same numbers from here.

const NORMAL_PROBE: float = 0.5
const HILL_PHASE_SKEW: float = 0.7
## A plateau's ramp covers the directions within this cosine of its ramp direction.
const RAMP_COS: float = 0.85
## A basin is flat-bottomed over this share of its radius.
const BASIN_FLAT: float = 0.45

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
var _plateaus: Array = []
var _basins: Array = []


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
	_plateaus = spec.get("plateaus", [])
	_basins = spec.get("basins", [])


func height(x: float, z: float) -> float:
	var p := Vector2(x, z)
	return _hill_height(p) + ridge_lift(p) - _ravine_cut(p) + _rim_lift(p) + plateau_lift(p) - _basin_cut(p)


## How much a plateau raises this spot: full height inside, a steep edge (a small cliff) all round except a gentle
## ramp in one direction.
func plateau_lift(p: Vector2) -> float:
	var lift: float = 0.0
	for plateau: Dictionary in _plateaus:
		var offset: Vector2 = p - Vector2(float(plateau["pos"][0]), float(plateau["pos"][1]))
		var ramp_dir: Vector2 = Vector2.from_angle(deg_to_rad(float(plateau["ramp_deg"])))
		var facing: float = offset.normalized().dot(ramp_dir) if offset.length() > 0.0 else 0.0
		var on_ramp: float = smoothstep(RAMP_COS, 1.0, facing)
		var edge: float = lerpf(float(plateau["edge"]), float(plateau["ramp"]), on_ramp)
		var radius: float = float(plateau["radius"])
		lift = maxf(lift, float(plateau["height"]) * (1.0 - smoothstep(radius - edge * 0.5, radius + edge * 0.5,
				offset.length())))
	return lift


func _basin_cut(p: Vector2) -> float:
	var cut: float = 0.0
	for basin: Dictionary in _basins:
		var d: float = p.distance_to(Vector2(float(basin["pos"][0]), float(basin["pos"][1])))
		cut = maxf(cut, float(basin["depth"]) * (1.0 - smoothstep(float(basin["radius"]) * BASIN_FLAT,
				float(basin["radius"]), d)))
	return cut


func normal(x: float, z: float) -> Vector3:
	var dx: float = height(x + NORMAL_PROBE, z) - height(x - NORMAL_PROBE, z)
	var dz: float = height(x, z + NORMAL_PROBE) - height(x, z - NORMAL_PROBE)
	return Vector3(-dx, 2.0 * NORMAL_PROBE, -dz).normalized()


## How much the ridge raises this spot (0 away from it): used for high-ground colouring and the crest rule.
func ridge_lift(p: Vector2) -> float:
	var d: float = segment_distance(p, _ridge_from, _ridge_to)
	return _ridge_height * exp(-d * d / (2.0 * _ridge_width * _ridge_width))


func ravine_distance(p: Vector2) -> float:
	var best: float = INF
	for k: int in _ravine.size() - 1:
		best = minf(best, segment_distance(p, _ravine[k], _ravine[k + 1]))
	return best


func ridge_distance(p: Vector2) -> float:
	return segment_distance(p, _ridge_from, _ridge_to)


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


static func segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)
