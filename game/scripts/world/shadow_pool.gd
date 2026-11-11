class_name ShadowPool
extends Node2D
## Lantern shadows, kept lean: a small pool of LightOccluder2D footprints that move to the trunks, pillars and walls
## nearest the Lamplighter's light (a zone has thousands of trees; only the few in the pool's reach cast shadows).

const POOL: int = 48
const REACH: float = 420.0
const REFRESH: float = 0.2
const POINTS: int = 6

var _casters: Array = []              ## [position, half size] of everything that may cast a shadow
var _pool: Array[LightOccluder2D] = []
var _t: float = 0.0


func add_caster(at: Vector2, half: Vector2) -> void:
	_casters.append([at, half])


func _ready() -> void:
	for k: int in mini(POOL, int(Atmosphere.quality()["shadows"])):
		var o := LightOccluder2D.new()
		o.occluder = OccluderPolygon2D.new()
		o.visible = false
		add_child(o)
		_pool.append(o)


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0 or Game.current == null:
		return
	_t = REFRESH
	var at: Vector2 = Game.current.player.global_position
	var near: Array = _casters.filter(func(c: Array) -> bool: return (c[0] as Vector2).distance_squared_to(at) < REACH * REACH)
	near.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector2).distance_squared_to(at) < (b[0] as Vector2).distance_squared_to(at))
	for k: int in _pool.size():
		_pool[k].visible = k < near.size()
		if k < near.size():
			_pool[k].position = near[k][0]
			_pool[k].occluder.polygon = _shape(near[k][1])


static func _shape(half: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k: int in POINTS:
		var a: float = TAU * k / POINTS
		pts.append(Vector2(cos(a) * half.x, sin(a) * half.y - half.y))
	return pts
