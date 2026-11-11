class_name TreeFade
extends Node
## In a 3/4 view the trees south of a path stand in front of whoever walks it. Trees whose canopy covers the
## Lamplighter or a nearby fight fade to see-through, then back. Trees are bucketed by area so only a few are
## checked each time.

const BUCKET: float = 128.0
const EVERY: float = 0.08
const SEE_THROUGH: float = 0.35
const FADE_SPEED: float = 6.0
const COVER_W: float = 30.0
const COVER_H: float = 110.0
const ENEMY_RANGE: float = 260.0

var _buckets: Dictionary = {}          ## Vector2i -> Array[Sprite2D]
var _faded: Dictionary = {}            ## Sprite2D -> target alpha
var _t: float = 0.0


func add(tree: Sprite2D) -> void:
	var k := Vector2i((tree.position / BUCKET).floor())
	if not _buckets.has(k):
		_buckets[k] = []
	(_buckets[k] as Array).append(tree)


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0 and Game.current != null:
		_t = EVERY
		_mark()
	for s: Sprite2D in _faded.keys():
		s.modulate.a = move_toward(s.modulate.a, float(_faded[s]), FADE_SPEED * delta)
		if float(_faded[s]) >= 1.0 and s.modulate.a >= 1.0:
			_faded.erase(s)


func _mark() -> void:
	var bodies: Array[Vector2] = [Game.current.player.global_position]
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.global_position.distance_to(bodies[0]) < ENEMY_RANGE:
			bodies.append(e.global_position)
	for s: Sprite2D in _faded.keys():
		_faded[s] = 1.0
	for b: Vector2 in bodies:
		for s: Sprite2D in _near(b):
			if _covers(s, b):
				_faded[s] = SEE_THROUGH


func _near(p: Vector2) -> Array:
	var out: Array = []
	var k := Vector2i((p / BUCKET).floor())
	for dy: int in [0, 1]:
		for dx: int in [-1, 0, 1]:
			out.append_array(_buckets.get(k + Vector2i(dx, dy), []))
	return out


## A tree covers a body when the body stands behind it (higher on screen) within its canopy.
func _covers(tree: Sprite2D, body: Vector2) -> bool:
	return tree.position.y > body.y and tree.position.y - body.y < COVER_H and absf(tree.position.x - body.x) < COVER_W
