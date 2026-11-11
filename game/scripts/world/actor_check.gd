class_name ActorCheck
extends RefCounted
## Bodies must never stand inside solid things: the Lamplighter, enemies and people are checked against every
## prop footprint, and enemies against each other (a little overlap is normal in a melee, a deep one is not).

const DEEP: float = 0.5
const SEE_THROUGH_OK: float = 0.6
const FEET_UP: float = 4.0


static func problems(g: Game) -> PackedStringArray:
	var out := PackedStringArray()
	var bodies: Array = [[g.player.global_position, g.player.radius, "the Lamplighter"]]
	for n: Node in g.get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		bodies.append([e.global_position, e.radius, e.display_name()])
	for n: Node in g.get_tree().get_nodes_in_group("interactables"):
		if n is Npc:
			bodies.append([(n as Npc).global_position, 0.0, (n as Npc).title])
	for b: Array in bodies:
		for f: Rect2 in g.layout.footprints():
			if _inside(b[0], b[1] * DEEP, f):
				out.append("%s stands inside a prop at %s" % [b[2], b[0]])
	return out


static func _inside(p: Vector2, r: float, f: Rect2) -> bool:
	return f.grow(-1.0).grow(r).has_point(p)


static func enemy_overlaps(g: Game) -> int:
	var es: Array = g.get_tree().get_nodes_in_group("enemies")
	var n: int = 0
	for i: int in es.size():
		for j: int in range(i + 1, es.size()):
			var a := es[i] as Enemy
			var b := es[j] as Enemy
			if a.global_position.distance_to(b.global_position) < (a.radius + b.radius) * DEEP:
				n += 1
	return n


## Tall things in front of a body (lower on screen) must not hide its feet unless they have faded see-through.
static func hidden(g: Game) -> PackedStringArray:
	var out := PackedStringArray()
	var bodies: Array = [g.player]
	bodies.append_array(g.get_tree().get_nodes_in_group("enemies"))
	for n: Node in g.get_tree().get_nodes_in_group("tall_props"):
		var s := n as Sprite2D
		if s.modulate.a < SEE_THROUGH_OK:
			continue
		var sz: Vector2 = s.texture.get_size() / Vector2(s.hframes, s.vframes)
		var r := Rect2(s.global_position + Vector2(-sz.x * 0.35, -sz.y), Vector2(sz.x * 0.7, sz.y))
		for b: Node2D in bodies:
			if s.global_position.y > b.global_position.y and r.has_point(b.global_position + Vector2(0, -FEET_UP)):
				out.append("%s hides someone's feet at %s" % [s.texture.resource_path.get_file(), b.global_position])
	return out
