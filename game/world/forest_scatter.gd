class_name ForestScatter
extends RefCounted
## Decides where trees stand: a looser forest inside the arena that keeps clearings, paths, the ravine floor and the
## ridge crest open, plus a dense tree line around the edge that bounds the arena naturally. Seeded, so the woods
## are the same every run.

var _layout: Dictionary
var _rules: Dictionary
var _shape: TerrainShape
var _rng: RandomNumberGenerator
var _placed: Array[Vector2] = []


func _init(layout: Dictionary, shape: TerrainShape, rng: RandomNumberGenerator) -> void:
	_layout = layout
	_rules = layout["trees"]
	_shape = shape
	_rng = rng


## Each tree as {pos: Vector2, kind: "pine"/"leafy", scale: float}.
func plan() -> Array[Dictionary]:
	var trees: Array[Dictionary] = []
	trees.append_array(_scatter(int(_rules["inner_count"]), float(_rules["inner_spacing"]), _inner_spot))
	trees.append_array(_scatter(int(_rules["ring_count"]), float(_rules["ring_spacing"]), _ring_spot))
	return trees


func _scatter(count: int, spacing: float, pick: Callable) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var attempts: int = int(_rules["max_attempts"])
	while out.size() < count and attempts > 0:
		attempts -= 1
		var spot: Vector2 = pick.call()
		if spot == Vector2.INF or _crowded(spot, spacing):
			continue
		_placed.append(spot)
		var scale: float = _rng.randf_range(_rules["scale_min"], _rules["scale_max"])
		out.append({ "pos": spot, "kind": _kind(), "scale": scale })
	return out


func _inner_spot() -> Vector2:
	var limit: float = float(_rules["ring_from"])
	var spot := Vector2(_rng.randf_range(-limit, limit), _rng.randf_range(-limit, limit))
	return spot if _inner_spot_is_open(spot) else Vector2.INF


func _ring_spot() -> Vector2:
	var from: float = float(_rules["ring_from"])
	var to: float = float(_rules["ring_to"])
	var spot := Vector2(_rng.randf_range(-to, to), _rng.randf_range(-to, to))
	var edge: float = maxf(absf(spot.x), absf(spot.y))
	return spot if edge >= from and edge <= to else Vector2.INF


func _inner_spot_is_open(spot: Vector2) -> bool:
	if _near_any(spot, _layout["clearings"], "radius", float(_rules["clearing_margin"])):
		return false
	if _near_any(spot, _layout["bushes"], "radius", float(_rules["bush_margin"])):
		return false
	if _near_any(spot, _layout["grass"], "radius", float(_rules["grass_margin"])):
		return false
	if _near_rock_or_log(spot) or _near_points(spot):
		return false
	if _shape.ravine_distance(spot) < float(_rules["ravine_margin"]):
		return false
	return _shape.ridge_distance(spot) >= float(_rules["ridge_crest_margin"])


func _near_any(spot: Vector2, items: Array, radius_key: String, margin: float) -> bool:
	for item: Dictionary in items:
		if spot.distance_to(Tuning.vec2(item["pos"])) < float(item[radius_key]) + margin:
			return true
	return false


func _near_rock_or_log(spot: Vector2) -> bool:
	for rock: Dictionary in _layout["rocks"]:
		var size: Array = rock["size"]
		var reach: float = maxf(float(size[0]), float(size[2])) * 0.5 + float(_rules["rock_margin"])
		if spot.distance_to(Tuning.vec2(rock["pos"])) < reach:
			return true
	for log_spec: Dictionary in _layout["logs"]:
		var reach: float = float(log_spec["length"]) * 0.5 + float(_rules["log_margin"])
		if spot.distance_to(Tuning.vec2(log_spec["pos"])) < reach:
			return true
	return false


func _near_points(spot: Vector2) -> bool:
	var points: Array = _layout["patrol_points"].duplicate()
	points.append(_layout["player_spawn"])
	points.append(_layout["bot_spawn"])
	for point: Array in points:
		if spot.distance_to(Tuning.vec2(point)) < float(_rules["point_margin"]):
			return true
	return false


func _crowded(spot: Vector2, spacing: float) -> bool:
	for other: Vector2 in _placed:
		if spot.distance_to(other) < spacing:
			return true
	return false


func _kind() -> String:
	return "pine" if _rng.randf() < float(_rules["pine_share"]) else "leafy"
