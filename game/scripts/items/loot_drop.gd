class_name LootDrop
extends RefCounted
## Where drops land: rings around the source on open walkable ground only — never in forest, water, a prop's
## footprint, on a bridge rail, or under the Lamplighter's feet (so clicking there is still a move) — spaced so
## icons never overlap. Labels are kept apart by LabelStack.

const RING0: float = 26.0
const RING_STEP: float = 20.0
const PER_RING: int = 6
const RINGS: int = 7
const CLEAR_OF_PLAYER: float = 34.0
const SPACING: float = 20.0
const ITEM_RADIUS: float = 8.0


static func free_spots(z: ZoneLayout, at: Vector2, n: int, player_pos: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var taken: Array[Vector2] = []
	for g: Node in Game.current.get_tree().get_nodes_in_group("ground_items"):
		taken.append((g as Node2D).global_position)
	for ring: int in RINGS:
		var count: int = PER_RING * (ring + 1)
		for k: int in count:
			var a: float = TAU * k / count + ring * 0.4
			var p: Vector2 = (at + Vector2(cos(a), sin(a) * 0.7) * (RING0 + RING_STEP * ring)).round()
			if _ok(z, p, out + taken, player_pos):
				out.append(p)
				if out.size() >= n:
					return out
	return out


static func _ok(z: ZoneLayout, p: Vector2, taken: Array[Vector2], player_pos: Vector2) -> bool:
	if p.distance_to(player_pos) < CLEAR_OF_PLAYER:
		return false
	if taken.any(func(t: Vector2) -> bool: return t.distance_to(p) < SPACING):
		return false
	var c: Vector2i = z.cell_of(p)
	return z.t(c) != ZoneLayout.T.BRIDGE and z.point_free(p, ITEM_RADIUS)
