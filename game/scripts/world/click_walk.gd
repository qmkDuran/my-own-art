class_name ClickWalk
extends RefCounted
## Click-to-walk: a left click on the map walks the player there along the shortest open path (breadth-first
## over free cells). Clicking a person, sign or door walks up to it, turns to face it and interacts.
## Any key press, a battle or a warp ends the walk.

const MAX_SEARCH: int = 2000
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var world: Overworld
var walking: bool = false
var _cancel: bool = false


func _init(w: Overworld) -> void:
	world = w


func cancel() -> void:
	_cancel = walking


func go(target: Vector2i) -> void:
	if walking or not world.map.in_bounds(target):
		return
	var talk: bool = _is_talkable(target)
	var path: Array[Vector2i] = path_to(world.player.cell, target, talk)
	if path.is_empty() and world.player.cell != target and not _adjacent(world.player.cell, target):
		Audio.sfx("bump")
		return
	walking = true
	_cancel = false
	var map_id: String = world.map.id
	var battles: int = world.battles.started
	for cell: Vector2i in path:
		if _cancel or world.busy or world.map.id != map_id or world.battles.started != battles:
			break
		await world.try_step(cell - world.player.cell)
		if world.player.cell != cell:
			break
	walking = false
	if talk and not _cancel and world.map.id == map_id and _adjacent(world.player.cell, target):
		world.player.face(target - world.player.cell)
		Game.facing = world.player.facing
		await world.interactions.interact()


func _adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


func _is_talkable(c: Vector2i) -> bool:
	for w: Walker in world.npcs:
		if w.cell == c:
			return true
	var o: Dictionary = world.map.object_at(c, Game.heal_stage)
	return o.has("talk") or o.get("talk_through", false)


## Shortest list of cells from start to goal (or to a cell next to it when `beside`); empty if none.
func path_to(start: Vector2i, goal: Vector2i, beside: bool) -> Array[Vector2i]:
	var came: Dictionary = {start: start}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty() and came.size() < MAX_SEARCH:
		var c: Vector2i = queue.pop_front()
		if (beside and _adjacent(c, goal)) or (not beside and c == goal):
			return _unwind(came, start, c)
		for d: Vector2i in DIRS:
			var n: Vector2i = c + d
			if not came.has(n) and world.is_free(n):
				came[n] = c
				queue.append(n)
	return []


func _unwind(came: Dictionary, start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var c: Vector2i = end
	while c != start:
		out.push_front(c)
		c = came[c]
	return out
