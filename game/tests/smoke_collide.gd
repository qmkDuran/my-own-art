class_name SmokeCollide
extends RefCounted
## Nothing ghosts through solid things: Wickstep into props, walls and water from eight directions; fast enemy moves
## (pounces, charges); knockback and Tether pulls into walls; and tall props only cover a body standing behind them
## (and then fade). Every step of every move is checked, so a pass-through between two frames is caught too.

const DIRS: int = 8
const RUN_UP: float = 70.0
const DASH_FRAMES: int = 16
const PULL: float = 2000.0
const BEHIND := Vector2(0, -18)
const IN_FRONT := Vector2(0, 30)

var t: Node
var g: Game
var p: Player


func _init(runner: Node) -> void:
	t = runner
	g = runner.get("g")
	p = runner.get("p")


func expect(ok: bool, what: String) -> void:
	t.call("expect", ok, what)


func run(h: ShotHelper) -> void:
	h.clear_near(100000.0)
	var prop: Dictionary = _thin_prop()
	expect(not prop.is_empty(), "a thin prop to dash into")
	if not prop.is_empty():
		expect(await _dashes((prop["foot"] as Rect2).get_center(), "a %s" % prop["kind"]), "Wickstep never ends in or passes through a %s (8 directions)" % prop["kind"])
	var edge: Vector2 = _wall_edge()
	expect(await _dashes(edge, "a wall"), "Wickstep never passes through the forest wall or water (8 directions)")
	expect(await _fast_enemy(edge), "a pouncing hound never passes through a wall")
	expect(await _pushed(edge), "knockback and Tether pulls never push a body into a wall")
	await _depth(h)


## Is this body position solid ground (not inside a footprint, not on blocked terrain)?
func _clear(at: Vector2, r: float) -> bool:
	if not g.layout.walkable_terrain(g.layout.cell_of(at)):
		return false
	for f: Rect2 in g.layout.footprints():
		if ActorCheck._inside(at, r * 0.5, f):
			return false
	return true


func _thin_prop() -> Dictionary:
	var best: Dictionary = {}
	for pr: Dictionary in g.layout.props:
		var f: Rect2 = pr["foot"]
		if f.size.x > 0.0 and f.size.x <= 24.0 and f.get_center().distance_to(p.global_position) < 3000.0:
			if best.is_empty() or f.size.x < (best["foot"] as Rect2).size.x:
				best = pr
	return best


## A walkable cell just south of a forest-wall or water cell.
func _wall_edge() -> Vector2:
	var z: ZoneLayout = g.layout
	var c0: Vector2i = z.cell_of(p.global_position)
	for r: int in range(1, 40):
		for y: int in range(c0.y - r, c0.y + r + 1):
			for x: int in range(c0.x - r, c0.x + r + 1):
				var c := Vector2i(x, y)
				if z.walkable(c) and not z.walkable_terrain(c + Vector2i.UP):
					return z.center_of(c + Vector2i.UP) + Vector2(0, z.cell * 0.5)
	return p.global_position


## Dash at `target` from 8 sides; every frame of every dash must be on clear ground.
func _dashes(target: Vector2, _what: String) -> bool:
	for k: int in DIRS:
		var dir := Vector2.RIGHT.rotated(TAU * k / DIRS)
		var start: Vector2 = g.layout.free_spot_near(target - dir * RUN_UP, p.radius)
		p.global_position = start
		p._dash_cd = 0.0
		p.busy_t = 0.0
		p.dash(target + dir * RUN_UP * 2.0)
		for f: int in DASH_FRAMES:
			await t.get_tree().physics_frame
			if not _clear(p.global_position, p.radius):
				print("SMOKE note: dash dir %d ended inside at %s" % [k, p.global_position])
				return false
	return true


func _fast_enemy(edge: Vector2) -> bool:
	p.global_position = g.layout.free_spot_near(edge + Vector2(0, -80), p.radius)
	var ok: bool = true
	if not g.layout.walkable(g.layout.cell_of(p.global_position)):
		p.global_position = g.layout.free_spot_near(edge + Vector2(0, 60), p.radius)
	var hound: Enemy = g.spawner.spawn("hound", g.layout.free_spot_near(edge + Vector2(0, 120), 14.0), "normal", [], 10)
	hound.wake()
	for f: int in 120:
		await t.get_tree().physics_frame
		ok = ok and _clear(hound.global_position, hound.radius)
	hound.queue_free()
	return ok


func _pushed(edge: Vector2) -> bool:
	var e: Enemy = g.spawner.spawn("husk", g.layout.free_spot_near(edge + Vector2(0, 30), 14.0), "normal", [], 10)
	e.stun_t = 2.0
	var ok: bool = true
	e.take_damage(1.0, true, Vector2.UP, {"knockback": PULL})      # a huge crit shove, straight at the wall
	for f: int in 30:
		await t.get_tree().physics_frame
		ok = ok and _clear(e.global_position, e.radius)
	e.pull_toward(edge + Vector2(0, -200), PULL)
	for f: int in 30:
		await t.get_tree().physics_frame
		ok = ok and _clear(e.global_position, e.radius)
	e.queue_free()
	return ok


## A tall prop covers a body only from in front (its base lower on screen), and then fades; the matron_fight case:
## a stalagmite-like prop just south of his feet.
func _depth(h: ShotHelper) -> void:
	var tall: Sprite2D = null
	for n: Node in t.get_tree().get_nodes_in_group("tall_props"):
		var s := n as Sprite2D
		if s.global_position.distance_to(p.global_position) < 4000.0 and _clear(s.global_position + BEHIND, p.radius) \
				and _clear(s.global_position + IN_FRONT, p.radius):
			tall = s
			break
	expect(tall != null, "a tall prop to stand behind")
	if tall == null:
		return
	p.global_position = tall.global_position + BEHIND
	await t.get_tree().create_timer(0.5).timeout
	var behind_ok: bool = not ActorCheck._over_legs(tall, p.global_position) or tall.modulate.a < ActorCheck.SEE_THROUGH_OK
	expect(behind_ok, "standing just behind a tall prop: it fades if its real shape covers his legs (alpha %.2f)" % tall.modulate.a)
	p.global_position = tall.global_position + IN_FRONT
	await t.get_tree().create_timer(0.5).timeout
	expect(p.global_position.y > tall.global_position.y and tall.modulate.a > 0.9, "standing in front of it: he draws over it and it stays solid (dy %d, alpha %.2f)" % [p.global_position.y - tall.global_position.y, tall.modulate.a])
