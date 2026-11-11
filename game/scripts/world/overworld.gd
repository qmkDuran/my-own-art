class_name Overworld
extends Node2D
## The overworld: shows the current map (baked ground + y-sorted props and people), walks the player on the
## grid, follows with the camera, and hands off to the helpers for talking, battles and the healing world.

signal map_loaded(id: String)

const T: int = 16
const WANDER_EVERY: float = 2.5
const INPUT_COOLDOWN: int = 2

var map: MapGrid
var painter: TerrainPainter = TerrainPainter.new()
var terrain: Sprite2D
var props: PropLayer
var things: Node2D
var player: Walker
var npcs: Array[Walker] = []
var npc_data: Dictionary = {}
var camera: Camera2D
var ui: CanvasLayer
var dialog: DialogueBox
var banner: MapBanner
var busy: bool = false
var interactions: WorldInteractions
var battles: BattleLauncher
var healing: HealSequence
var _wander_clock: float = 0.0
## Frames to ignore input after an event ends, so the press that closed it does not start another.
var _cooldown: int = 0


func _ready() -> void:
	camera = Camera2D.new()
	add_child(camera)
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	dialog = DialogueBox.new()
	ui.add_child(dialog)
	banner = MapBanner.new()
	ui.add_child(banner)
	interactions = WorldInteractions.new(self)
	battles = BattleLauncher.new(self)
	healing = HealSequence.new(self)
	Game.heal_stage_changed.connect(healing.queue_heal)
	load_map(Game.map_id, Game.cell, Game.facing)


func load_map(id: String, cell: Vector2i, facing: Vector2i) -> void:
	for child: Node in [terrain, things]:
		if child != null:
			child.queue_free()
	npcs.clear()
	npc_data.clear()
	map = MapGrid.load_map(id)
	Game.map_id = id
	Game.cell = cell
	terrain = Sprite2D.new()
	terrain.centered = false
	terrain.texture = painter.bake(map, Game.heal_stage)
	terrain.z_index = -10
	add_child(terrain)
	things = Node2D.new()
	things.y_sort_enabled = true
	add_child(things)
	props = PropLayer.new()
	props.build(map, Game.heal_stage)
	things.add_child(props)
	_spawn_people(cell, facing)
	Audio.music(map.music)
	banner.show_name(map.title)
	_update_camera()
	map_loaded.emit(id)


func _spawn_people(cell: Vector2i, facing: Vector2i) -> void:
	player = Walker.new().setup("player", cell, facing)
	props.add_child(player)
	for o: Dictionary in map.objects:
		if o["kind"] in ["npc", "trainer"] and interactions.is_shown(o):
			var w: Walker = Walker.new().setup(String(o["person"]), MapGrid.cell_of(o["cell"]),
				MapGrid.dir_of(String(o.get("facing", "down"))))
			props.add_child(w)
			npcs.append(w)
			npc_data[w] = o
	_update_grass(player)


func _process(delta: float) -> void:
	_update_camera()
	_wander(delta)
	if busy:
		_cooldown = INPUT_COOLDOWN
		return
	if player.moving:
		return
	if _cooldown > 0:
		_cooldown -= 1
		return
	if Input.is_action_just_pressed("accept"):
		interactions.interact()
	elif Input.is_action_just_pressed("menu"):
		interactions.open_menu()
	else:
		var dir: Vector2i = _held_direction()
		if dir != Vector2i.ZERO:
			try_step(dir)


func _held_direction() -> Vector2i:
	for pair: Array in [["move_up", Vector2i.UP], ["move_down", Vector2i.DOWN], ["move_left", Vector2i.LEFT],
			["move_right", Vector2i.RIGHT]]:
		if Input.is_action_pressed(String(pair[0])):
			return pair[1]
	return Vector2i.ZERO


func is_free(c: Vector2i) -> bool:
	if not map.walkable(c, Game.heal_stage):
		return false
	for w: Walker in npcs:
		if w.cell == c:
			return false
	return player == null or player.cell != c


## Takes one step if the way is open; then warps, trainer sight and encounters get their turn.
func try_step(dir: Vector2i) -> void:
	var target: Vector2i = player.cell + dir
	if not is_free(target):
		player.face(dir)
		Game.facing = dir
		return
	busy = true
	await player.step(dir)
	Game.cell = player.cell
	Game.facing = dir
	_update_grass(player)
	if Game.lead() != null:
		Bond.walk_step(Game.lead())
	busy = false
	await _after_step()


func _after_step() -> void:
	var warp: Dictionary = map.warp_at(player.cell)
	if not warp.is_empty():
		await warp_to(warp)
		return
	if await interactions.check_trainers():
		return
	await battles.check_encounter()


func warp_to(to: Dictionary) -> void:
	busy = true
	Audio.sfx("door")
	await Fade.out(ui)
	load_map(String(to["map"]), MapGrid.cell_of(to["cell"]), MapGrid.dir_of(String(to["facing"])))
	await Fade.into(ui)
	busy = false


func _update_grass(w: Walker) -> void:
	var dry: bool = map.is_withered(w.cell, Game.heal_stage)
	w.set_in_grass(map.is_tall(w.cell), load("res://art/tiles/tall_grass_front%s.png" % ("_withered" if dry else "")))


func _update_camera() -> void:
	if player == null:
		return
	var view: Vector2 = get_viewport_rect().size
	var map_px := Vector2(map.size * T)
	var target: Vector2 = player.position - Vector2(0, T / 2)
	for axis: int in 2:
		if map_px[axis] <= view[axis]:
			target[axis] = map_px[axis] / 2
		else:
			target[axis] = clampf(target[axis], view[axis] / 2, map_px[axis] - view[axis] / 2)
	camera.position = target.round()


func _wander(delta: float) -> void:
	_wander_clock += delta
	if _wander_clock < WANDER_EVERY or busy:
		return
	_wander_clock = 0.0
	for w: Walker in npcs:
		var o: Dictionary = npc_data[w]
		if o.get("wander", false) and not w.moving:
			var home: Vector2i = MapGrid.cell_of(o["cell"])
			var dir: Vector2i = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT][Game.rng.randi_range(0, 3)]
			if is_free(w.cell + dir) and (w.cell + dir - home).length() <= 1.5:
				w.step(dir)
			else:
				w.face(dir)


func refresh_terrain() -> void:
	terrain.texture = painter.bake(map, Game.heal_stage)
