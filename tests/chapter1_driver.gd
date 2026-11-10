extends Node
## Plays Chapter 1's greybox automatically, from the main menu to the "Chapter 2" card:
## hero picker, movement, examine/pickup/doors, dialogue choices, the Wade and street fights,
## the stray dog, a deliberate death and retry, inventory use, zone transitions and flags.
##
##   godot --path . res://tests/chapter1_driver.tscn                 (headless works too)
##   godot --path . res://tests/chapter1_driver.tscn -- --shots=DIR   (also saves PNGs)
##
## Prints "DRIVER PASS" or "DRIVER FAIL" and quits with exit code 0 / 1.

const MENU := "res://scenes/menu/main_menu.tscn"
const TIMEOUT := 600.0

var _failures: Array[String] = []
var _cards: Array[String] = []
var _shots_dir := ""
var _shots_taken: Dictionary = {}
var _teleports := 0
var _elapsed := 0.0


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
	Events.card_shown.connect(_on_card)
	GameState.delete_save()
	_run.call_deferred()


var _status_time := 0.0


var _chapter_2_time := INF


func _on_card(_kind: String, title: String, _subtitle: String) -> void:
	_cards.append(title)
	if title == "Chapter 2":
		_chapter_2_time = _elapsed


func _process(delta: float) -> void:
	_elapsed += delta
	_status_time += delta
	if _status_time > 10.0 and Router.game and Router.game.player:
		_status_time = 0.0
		print("[driver] status t=%.0f zone=%s tile=%s dialogue='%s' choosing=%s busy=%s" % [_elapsed, _zone(), _tile_of_player(), Dialogue.current_ref(), Dialogue.box.is_choosing(), Router.is_busy()])
	if _elapsed > TIMEOUT:
		_fail("global timeout")
		_finish()


func _run() -> void:
	# Keep this driver alive across scene changes.
	var placeholder := Node.new()
	get_tree().root.add_child(placeholder)
	get_tree().current_scene = placeholder
	get_tree().change_scene_to_file(MENU)
	await _seconds(1.0)
	await _menu()
	await _house_evening()
	await _street_dusk()
	await _store()
	await _street_after()
	await _house_night()
	_finish()


# --- Chapter beats ---------------------------------------------------------------

func _menu() -> void:
	var menu := get_tree().current_scene
	_check(menu.has_method("open_picker"), "main menu loaded")
	menu.call("open_picker")
	menu.call("choose", "female", 4, "bun")
	await _seconds(0.6)
	_shot("01_hero_picker")
	_check(GameState.skin_tone == 4, "skin tone picked")
	menu.call("start")
	await _wait_for(func() -> bool: return Router.game != null and Router.game.zone != null and not Router.is_busy(), 15.0)
	_check(_cards.has("Chapter 1"), "chapter 1 card shown")
	_check(GameState.hair_style == "bun" and GameState.gender == "female", "hero choices saved in game state")
	await _finish_dialogue()


func _house_evening() -> void:
	_check(_zone() == "house", "starts in the house")
	# bedroom -> through the bedroom doorway -> living room -> kitchen opening -> kitchen
	await _go([Vector2(144, 240), Vector2(144, 430), Vector2(470, 430), Vector2(470, 270)])
	await _finish_dialogue()
	_shot("02_kitchen_mom")
	await _go([Vector2(440, 270), Vector2(440, 150), Vector2(650, 140)])
	await _face(Vector2.UP)
	await _interact()
	await _go([Vector2(418, 140)])
	await _face(Vector2.UP)
	await _interact()
	await _go([Vector2(700, 140)])
	await _face(Vector2.UP)
	await _interact([0, 0])
	_check(GameState.flags.is_set("C1_ERRAND"), "dinner done, errand given")
	_check(GameState.flags.get_value("C1_GRACE") == "bowed", "grace choice stored")
	# kitchen -> living room -> doorway into the foyer -> the coat hooks by the stairs
	await _go([Vector2(660, 270), Vector2(480, 270), Vector2(480, 512), Vector2(640, 512), Vector2(700, 410)])
	await _face(Vector2.UP)
	await _interact()
	_check(GameState.inventory.has_item("mom_card"), "took Mom's card")
	await _seconds(0.3)
	await _finish_dialogue([0])
	_check(GameState.flags.get_value("C1_LAST_WORDS") == "kind", "last words choice stored")
	await _go([Vector2(720, 590)])
	await _face(Vector2.DOWN)
	await _interact()
	await _wait_zone("street")


func _street_dusk() -> void:
	await _finish_dialogue()
	_shot("03_street_dusk")
	# down the front path, then east along the curb side of the sidewalk to the market's lot
	await _go([Vector2(208, 520), Vector2(208, 592), Vector2(800, 592), Vector2(1400, 592), Vector2(2000, 592), Vector2(2000, 470)])
	await _face(Vector2.UP)
	await _interact()
	await _wait_zone("store")


func _store() -> void:
	await _finish_dialogue()
	# up the first cross aisle into aisle 2 (Wade's background lines)
	await _go([Vector2(320, 440), Vector2(320, 262), Vector2(420, 262)])
	await _finish_dialogue()
	await _go([Vector2(320, 262), Vector2(320, 140), Vector2(366, 140)])
	await _face(Vector2.UP)
	await _interact()
	await _go([Vector2(140, 140)])
	await _face(Vector2.UP)
	await _interact()
	await _go([Vector2(300, 140), Vector2(300, 440), Vector2(178, 440)])
	await _face(Vector2.UP)
	await _interact()
	_check(GameState.inventory.has_item("milk") and GameState.inventory.has_item("bread") and GameState.inventory.has_item("battery_9v"), "shopping list complete")
	_shot("04_store_shopping")
	await _go([Vector2(150, 414)])
	await _face(Vector2.UP)
	await _interact([], func() -> void:
		if GameState.flags.is_set("vanished"):
			_shot("05_store_vanished"))
	_check(GameState.flags.is_set("vanished"), "the vanishing happened")
	_check(GameState.flags.is_set(ZoneEntityLink.gone_flag("hollis")), "Hollis is gone")
	_check(GameState.flags.get_value("C1_LOOTER") == "fought", "chose to fight Wade")
	await _fight(["wade_enemy"], 40.0)
	await _finish_dialogue()
	_check(GameState.flags.is_set("wade_gone"), "Wade fight resolved")
	await _go([Vector2(300, 440), Vector2(300, 140), Vector2(66, 138)])
	await _face(Vector2.UP)
	await _interact()
	_check(GameState.inventory.has_item("medicine"), "picked up painkillers")
	await _use_item("medicine")
	await _go([Vector2(300, 140), Vector2(300, 440), Vector2(336, 470)])
	await _face(Vector2.DOWN)
	await _interact()
	await _wait_zone("street")


func _street_after() -> void:
	await _finish_dialogue()
	_shot("07_street_chaos")
	# Death and retry at the checkpoint saved on entering the street.
	Router.game.player.health.take_damage(999)
	_check(Router.game.player.state == Player.State.DEAD, "player can die")
	await _seconds(1.0)
	await _wait_for(func() -> bool: return not Router.is_busy() and Router.game.player.state != Player.State.DEAD, 10.0)
	_check(_zone() == "street" and GameState.flags.is_set("vanished") and GameState.hp == GameState.max_hp, "retry at checkpoint restores the street")
	await _finish_dialogue()
	# West along the north sidewalk: Biscuit is in front of the Okoros' (calm without having met
	# Mrs. Albright fails, so he snaps), Dana is in the wreck, the looter waits further on.
	await _go([Vector2(2000, 560), Vector2(1745, 560)], [0])
	await _finish_dialogue([0])
	if Router.game.zone.is_entity_active("biscuit"):
		await _fight(["biscuit"], 25.0)
	await _finish_dialogue()
	_check(GameState.flags.is_set("C1_BISCUIT"), "Biscuit beat resolved")
	await _go([Vector2(1300, 560)])
	await _face(Vector2.DOWN)
	await _interact([0])
	_check(GameState.flags.is_set("C1_HELPED_DANA"), "Dana choice stored")
	await _go([Vector2(1040, 560)])
	await _finish_dialogue()
	await _fight(["street_looter"], 40.0)
	await _finish_dialogue()
	_check(GameState.flags.is_set("street_looter_defeated"), "street looter defeated")
	_shot("08_street_after_fight")
	await _go([Vector2(600, 560), Vector2(208, 560), Vector2(208, 446)])
	await _face(Vector2.UP)
	await _interact()
	await _wait_zone("house")


func _house_night() -> void:
	await _finish_dialogue()
	# foyer -> living room -> kitchen: Mom's chair
	await _go([Vector2(720, 520), Vector2(480, 512), Vector2(480, 300), Vector2(505, 264)])
	await _face(Vector2.UP)
	await _interact()
	_shot("09_empty_chair")
	await _go([Vector2(580, 270)])
	await _face(Vector2.UP)
	await _interact()
	_check(GameState.flags.is_set("C1_READ_LETTER") and GameState.inventory.has_item("letter"), "found the Bible and the letter")
	_check(GameState.flags.is_set("C1_DAWN"), "dawn")
	await _go([Vector2(660, 270), Vector2(774, 140)])
	await _face(Vector2.UP)
	_shot("10_dawn")
	await _interact([], func() -> void:
		if _cards.has("Chapter 2") and _elapsed - _chapter_2_time > 1.2:
			_shot("11_chapter_2_card"))
	_check(_cards.has("Chapter 2"), "reached the Chapter 2 card")
	await _wait_for(func() -> bool: return get_tree().current_scene != null and get_tree().current_scene.has_method("open_picker"), 15.0)
	_check(GameState.chapter == 2 and GameState.has_save(), "chapter progress saved")


# --- Actions -------------------------------------------------------------------------

## Walks through pixel waypoints (feet position).
func _go(points: Array, choices: Array = []) -> void:
	for point: Vector2 in points:
		await _walk_to(point / Tiles.SIZE - Vector2(0.5, 0.5), choices)


func _walk(points: Array, choices: Array = []) -> void:
	for point: Vector2 in points:
		await _walk_to(point, choices)


func _walk_to(tile: Vector2, choices: Array) -> void:
	var target := (tile + Vector2(0.5, 0.5)) * Tiles.SIZE
	var best := INF
	var stuck := 0.0
	var time := 0.0
	while time < 12.0:
		if Dialogue.is_running() or Router.is_busy():
			_release_moves()
			await _finish_dialogue(choices)
			continue
		var player := Router.game.player
		var offset := target - player.global_position
		if offset.length() < 4.0:
			break
		_press_direction(offset)
		await get_tree().physics_frame
		time += get_physics_process_delta_time()
		if offset.length() < best - 0.5:
			best = offset.length()
			stuck = 0.0
		else:
			stuck += get_physics_process_delta_time()
		if stuck > 1.5:
			break
	_release_moves()
	var remaining := target.distance_to(Router.game.player.global_position)
	if remaining > 8.0:
		_teleports += 1
		print("[driver] stuck walking to %s (%.0f px away); teleporting" % [tile, remaining])
		Router.game.player.global_position = target
	await _frames(2)


func _press_direction(offset: Vector2) -> void:
	var dead := 2.0
	_set_action("move_right", offset.x > dead)
	_set_action("move_left", offset.x < -dead)
	_set_action("move_down", offset.y > dead)
	_set_action("move_up", offset.y < -dead)


func _set_action(action: String, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _release_moves() -> void:
	for action: String in ["move_left", "move_right", "move_up", "move_down", "run", "attack", "dodge"]:
		Input.action_release(action)


func _face(direction: Vector2) -> void:
	Router.game.player.facing = direction
	await _frames(2)


func _press(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
	await _frames(2)


## Presses interact on whatever is in front, then plays out any dialogue it starts.
func _interact(choices: Array = [], on_frame: Callable = Callable()) -> void:
	var focused := Router.game.player.focused_interactable()
	_check(focused != null, "something to interact with at %s in %s" % [_tile_of_player(), _zone()])
	if focused == null:
		_debug_nearby()
	await _press("interact")
	await _frames(4)
	await _finish_dialogue(choices, on_frame)


## Advances dialogue (and picks choices from the queue, default first option) until it ends.
func _finish_dialogue(choices: Array = [], on_frame: Callable = Callable()) -> void:
	var queue := choices.duplicate()
	var quiet := 0
	while quiet < 20:
		if on_frame.is_valid():
			on_frame.call()
		if Dialogue.is_running() or Router.is_busy():
			quiet = 0
			if not Dialogue._has_box():
				await _frames(1)
			elif Dialogue.box.is_choosing():
				var index: int = queue.pop_front() if not queue.is_empty() else 0
				for i in index:
					await _press("move_down")
				await _press("interact")
			elif Dialogue.box.is_open():
				await _press("interact")
			else:
				await _frames(1)
		else:
			quiet += 1
			await _frames(1)


## Fights the given enemies (zone entity ids) until each is beaten (dead or fled).
func _fight(ids: Array, timeout: float) -> void:
	var time := 0.0
	while time < timeout:
		if Dialogue.is_running():
			_release_moves()
			await _finish_dialogue()
			continue
		var enemies := Router.game.zone.enemies().filter(func(e: Enemy) -> bool: return ids.has(e.entity_id) and not e.is_defeated())
		if enemies.is_empty():
			break
		var player := Router.game.player
		enemies.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.global_position.distance_to(player.global_position) < b.global_position.distance_to(player.global_position))
		var enemy: Enemy = enemies[0]
		var offset := enemy.global_position - player.global_position
		if enemy.state == Enemy.State.WINDUP and offset.length() < 60.0 and randf() < 0.5:
			_release_moves()
			_press_direction(-offset)
			await _press("dodge")
		elif offset.length() > 30.0:
			_press_direction(offset)
		else:
			_release_moves()
			player.facing = offset.normalized()
			await _press("attack")
		await get_tree().physics_frame
		time += get_physics_process_delta_time()
	_release_moves()
	# Fleeing or falling enemies count as beaten once they leave the zone.
	await _wait_for(func() -> bool: return ids.all(func(id: String) -> bool: return not Router.game.zone.is_entity_active(id)), 8.0)
	await _frames(10)


func _use_item(item_id: String) -> void:
	GameState.set_hp(GameState.max_hp - 3)
	Router.game.player.sync_health()
	var hp_before := GameState.hp
	await _press("inventory")
	_check(Router.game.inventory_panel.is_open(), "inventory opens")
	var ids := GameState.inventory.item_ids()
	for i in ids.find(item_id):
		await _press("move_right")
	_shot("06_inventory")
	await _press("interact")
	_check(GameState.hp > hp_before, "using %s heals" % item_id)
	await _press("inventory")
	await _seconds(0.5)


func _debug_nearby() -> void:
	var player := Router.game.player
	print("[driver]   player at %s facing %s state %s" % [player.global_position, player.facing, player.state])
	for node: Node in get_tree().root.find_children("*", "Interactable", true, false):
		var area := node as Interactable
		if area.global_position.distance_to(player.global_position) < 80.0:
			print("[driver]   near: %s at %s visible=%s mode=%s" % [area.get_parent().name, area.global_position, area.is_visible_in_tree(), area.can_process()])


# --- Helpers ---------------------------------------------------------------------

func _wait_zone(zone_id: String) -> void:
	await _wait_for(func() -> bool: return _zone() == zone_id and not Router.is_busy(), 10.0)
	_check(_zone() == zone_id, "arrived in %s" % zone_id)


func _wait_for(condition: Callable, timeout: float) -> void:
	var time := 0.0
	while not condition.call() and time < timeout:
		await get_tree().process_frame
		time += get_process_delta_time()


func _zone() -> String:
	return Router.game.zone.zone_id if Router.game and Router.game.zone else ""


func _tile_of_player() -> Vector2:
	return (Router.game.player.global_position / Tiles.SIZE).snapped(Vector2(0.1, 0.1))


## Waits physics frames: gameplay (movement, interaction, input) runs in the physics step.
func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	if _shots_dir.is_empty() or _shots_taken.has(name):
		return
	_shots_taken[name] = true
	var image := get_viewport().get_texture().get_image()
	image.save_png(_shots_dir.path_join("%s.png" % name))


func _check(ok: bool, what: String) -> void:
	if ok:
		print("[driver] ok: ", what)
	else:
		_fail(what)


func _fail(what: String) -> void:
	_failures.append(what)
	print("[driver] FAIL: ", what)


func _finish() -> void:
	set_process(false)
	print("[driver] cards: ", _cards)
	print("[driver] flags: ", GameState.flags.to_dict().keys().size(), " set; teleports: ", _teleports)
	if _teleports > 0:
		_fail("%d stuck walks needed a teleport" % _teleports)
	print("DRIVER PASS" if _failures.is_empty() else "DRIVER FAIL: %s" % ", ".join(_failures))
	var code := 0 if _failures.is_empty() else 1
	AudioManager.shutdown()
	await _frames(5)
	get_tree().quit(code)
