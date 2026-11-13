class_name TacticalEval
extends RefCounted
## Scores places to stand. Candidate points are sampled in rings around a centre, plus every hiding spot and the
## lee side of every trunk and boulder nearby, all snapped to the navmesh. Each point gets features (covered from the
## threat, sightline to it, concealment, high ground, escape routes, distance band, travel cost, cutting off the
## player's usual escape) and a purpose ("cover", "flank", "ambush", "retreat") weighs them from data/ai.json. The
## last ranking is kept for the F3 overlay.

const NAVMESH_TOLERANCE: float = 0.5
const NEAR_RADIUS_SHARE: float = 1.2
## How far behind a trunk or boulder (beyond touching it) a lee-side point sits.
const LEE_GAP: float = 0.4

var last_ranking: Array[Dictionary] = []
var _woods: Woods
var _bot: Creature
var _senses: Perception
var _model: PlayerModel


func _init(woods: Woods, bot: Creature, senses: Perception, model: PlayerModel) -> void:
	_woods = woods
	_bot = bot
	_senses = senses
	_model = model


## The best place for a purpose near `around`, judged against a threat (usually the player's last known spot).
## Returns {} when nothing walkable was found.
func best(purpose: String, around: Vector3, threat: Vector3) -> Dictionary:
	var ranking: Array[Dictionary] = rank(purpose, around, threat)
	return ranking[0] if not ranking.is_empty() else {}


func rank(purpose: String, around: Vector3, threat: Vector3) -> Array[Dictionary]:
	var ranking: Array[Dictionary] = []
	for point: Vector3 in candidates(around, threat):
		var features: Dictionary = features_at(point, threat)
		ranking.append({ "pos": point, "score": weigh(purpose, features, point, threat), "features": features })
	ranking.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	last_ranking = ranking
	return ranking


func score_point(purpose: String, point: Vector3, threat: Vector3) -> float:
	return weigh(purpose, features_at(point, threat), point, threat)


func candidates(around: Vector3, threat: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var radii: Array = Tuning.ai["tactics"]["sample_radii"]
	var angles: int = int(Tuning.ai_f("tactics", "sample_angles"))
	for radius: float in radii:
		for k: int in angles:
			_add_walkable(points, around + Vector3.FORWARD.rotated(Vector3.UP, TAU * k / angles) * radius)
	var reach: float = float(radii.back()) * NEAR_RADIUS_SHARE
	for spot: HidingSpot in _woods.hiding_spots:
		if spot.global_position.distance_to(around) <= reach:
			_add_walkable(points, spot.global_position)
	for cover: Dictionary in _woods.cover_objects:
		var centre: Vector3 = cover["pos"]
		if centre.distance_to(around) <= reach:
			var away: Vector3 = Vector3(centre.x - threat.x, 0.0, centre.z - threat.z).normalized()
			_add_walkable(points, centre + away * (float(cover["radius"]) + Creature.BODY_RADIUS + LEE_GAP))
	return points


func features_at(point: Vector3, threat: Vector3) -> Dictionary:
	var world: World3D = _woods.get_world_3d()
	var chest: Vector3 = Vector3.UP * Tuning.f("perception", "chest_height")
	var eye: Vector3 = Vector3.UP * Tuning.f("perception", "eye_height")
	return {
		"cover": 1.0 if _solid_cover(world, threat + eye, point + chest) else 0.0,
		"sightline": 1.0 if Sight.clear(world, point + eye, threat + chest) else 0.0,
		"concealment": 1.0 if _in_hiding_spot(point) else 0.0,
		"high_ground": clampf((point.y - threat.y) / Tuning.ai_f("tactics", "high_ground_full"), 0.0, 1.0),
		"escape": _escape_share(point),
		"distance": Vector2(point.x - threat.x, point.z - threat.z).length(),
		"travel": clampf(point.distance_to(_bot.global_position) / Tuning.ai_f("tactics", "travel_full"), 0.0, 1.0),
	}


func weigh(purpose: String, features: Dictionary, point: Vector3, threat: Vector3) -> float:
	var weights: Dictionary = Tuning.ai["tactics"]["purposes"][purpose]
	var total: float = float(weights.get("band", 0.0)) * _band(features["distance"], weights)
	for feature: String in ["cover", "sightline", "concealment", "high_ground", "escape", "travel"]:
		total += float(weights.get(feature, 0.0)) * float(features[feature])
	total += float(weights.get("high_ground", 0.0)) * float(features["high_ground"]) * _high_ground_habit()
	return total + float(weights.get("cut_off", 0.0)) * _cut_off(point, threat)


## A player who likes the ridge makes the high ground worth more to the bot (as far as it uses memory).
func _high_ground_habit() -> float:
	return _model.high_ground_share() * Difficulty.setting("memory_use")


## 1 inside the purpose's distance band, falling off over one band-width outside it.
static func _band(distance: float, weights: Dictionary) -> float:
	var low: float = float(weights["band_min"])
	var high: float = float(weights["band_max"])
	var width: float = maxf(high - low, 1.0)
	if distance < low:
		return clampf(1.0 - (low - distance) / width, 0.0, 1.0)
	return clampf(1.0 - (distance - high) / width, 0.0, 1.0)


## How well a point sits across the way this player usually runs (learned, scaled by how much memory is used).
func _cut_off(point: Vector3, threat: Vector3) -> float:
	var flee: Vector3 = _model.flee_direction()
	var offset: Vector3 = point - threat
	offset.y = 0.0
	if flee == Vector3.ZERO or offset.length() == 0.0:
		return 0.0
	return maxf(flee.dot(offset.normalized()), 0.0) * Difficulty.setting("memory_use")


## Covered at the point and half a body to either side, so standing a little off the exact spot still hides.
static func _solid_cover(world: World3D, eye: Vector3, chest: Vector3) -> bool:
	var side: Vector3 = (chest - eye).cross(Vector3.UP).normalized() * Creature.BODY_RADIUS
	for offset: Vector3 in [Vector3.ZERO, side, -side]:
		if Sight.clear(world, eye, chest + offset):
			return false
	return true


func _escape_share(point: Vector3) -> float:
	var directions: int = int(Tuning.ai_f("tactics", "escape_directions"))
	var probe: float = Tuning.ai_f("tactics", "escape_probe")
	var open: int = 0
	for k: int in directions:
		var out: Vector3 = point + Vector3.FORWARD.rotated(Vector3.UP, TAU * k / directions) * probe
		var snapped: Vector3 = _woods.on_navmesh(out)
		if Vector2(snapped.x - out.x, snapped.z - out.z).length() <= NAVMESH_TOLERANCE:
			open += 1
	return float(open) / directions



func _in_hiding_spot(point: Vector3) -> bool:
	for spot: HidingSpot in _woods.hiding_spots:
		var offset: Vector3 = point - spot.global_position
		if Vector2(offset.x, offset.z).length() <= spot.radius - Creature.BODY_RADIUS:
			return true
	return false


func _add_walkable(points: Array[Vector3], wanted: Vector3) -> void:
	var snapped: Vector3 = _woods.on_navmesh(wanted)
	if Vector2(snapped.x - wanted.x, snapped.z - wanted.z).length() <= NAVMESH_TOLERANCE:
		points.append(snapped)
