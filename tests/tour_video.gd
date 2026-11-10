extends Node
## A ~45 s walkthrough for review videos: the hero walks Linden Court at dusk, goes into the
## house through the front door, walks through the foyer and living room, comes back out the
## front door, walks (then runs) to Ridge Mart and goes in through its door.
##
##   xvfb-run -a godot --rendering-driver opengl3 --path . res://tests/tour_video.tscn \
##       --fixed-fps 60 --write-movie /tmp/tour.avi
##   ffmpeg -i /tmp/tour.avi -c:v libx264 -pix_fmt yuv420p -crf 18 tour.mp4

var _hero := ["female", 2, "bob"]


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--hero="):
			var parts := arg.trim_prefix("--hero=").split(":")
			_hero = [parts[0], int(parts[1]), parts[2]]
	_run.call_deferred()


func _run() -> void:
	GameState.delete_save()
	var placeholder := Node.new()
	get_tree().root.add_child(placeholder)
	get_tree().current_scene = placeholder
	Router.start_new_game(_hero[0], _hero[1], _hero[2])
	while Router.game == null or Router.game.zone == null:
		await get_tree().process_frame
	print("[tour] game started")
	await _settle()
	print("[tour] settled")
	GameState.flags.load_dict({})
	for flag: String in ["C1_ERRAND", "C1_LAST_WORDS", "took_card"]:
		GameState.flags.set_flag(flag)
	# no story dialogue in the review video: mark every entry script and trigger as done
	for zone_id: String in ["street", "house", "store"]:
		var zone: Dictionary = DB.zone(zone_id)
		for entry: Variant in zone.get("on_enter", []):
			GameState.flags.set_flag("done:" + String((entry as Dictionary).get("id", "")))
		for entry: Variant in zone.get("entities", []):
			if String((entry as Dictionary).get("kind", "")) == "trigger":
				GameState.flags.set_flag("done:" + String(entry.get("id", "")))
	Router.game.load_zone("street", "", Vector2(560, 560))
	Router.game.player.facing = Vector2.LEFT
	await _seconds(1.0)
	# along the sidewalk to the Hale house, up the front path, in through the front door
	await _go([Vector2(208, 560), Vector2(208, 446)])
	await _use(Vector2.UP)
	print("[tour] door -> house")
	await _wait_zone("house")
	print("[tour] in house")
	await _seconds(0.6)
	# foyer -> doorway -> living room, look around, back to the front door
	await _go([Vector2(720, 500), Vector2(600, 512), Vector2(430, 512), Vector2(430, 440)])
	await _seconds(0.8)
	await _go([Vector2(600, 512), Vector2(720, 520), Vector2(720, 590)])
	await _use(Vector2.DOWN)
	await _wait_zone("street")
	print("[tour] back on the street")
	await _seconds(0.4)
	# down to the curb side, east along the court, running the second half, into the market
	await _go([Vector2(208, 592), Vector2(900, 592)])
	await _go([Vector2(1500, 592), Vector2(2000, 592)], true)
	await _go([Vector2(2000, 470)])
	await _use(Vector2.UP)
	await _wait_zone("store")
	print("[tour] in the store")
	await _seconds(0.4)
	await _go([Vector2(320, 440), Vector2(320, 262), Vector2(480, 262), Vector2(500, 150)])
	await _seconds(1.5)
	AudioManager.shutdown()
	get_tree().quit()


func _go(points: Array, run: bool = false) -> void:
	for target: Vector2 in points:
		var time := 0.0
		while time < 25.0:
			var offset := target - Router.game.player.global_position
			if offset.length() < 4.0:
				break
			var dead := 2.0
			_hold("move_right", offset.x > dead)
			_hold("move_left", offset.x < -dead)
			_hold("move_down", offset.y > dead)
			_hold("move_up", offset.y < -dead)
			_hold("run", run)
			await get_tree().physics_frame
			time += get_physics_process_delta_time()
	for action: String in ["move_left", "move_right", "move_up", "move_down", "run"]:
		Input.action_release(action)
	await get_tree().physics_frame


func _hold(action: String, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _use(direction: Vector2) -> void:
	Router.game.player.facing = direction
	await _seconds(0.3)
	Input.action_press("interact")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("interact")


func _wait_zone(zone_id: String) -> void:
	while Router.game.zone == null or Router.game.zone.zone_id != zone_id or Router.is_busy():
		await get_tree().process_frame


func _settle() -> void:
	var quiet := 0
	while quiet < 30:
		if Dialogue.is_running() or Router.is_busy():
			quiet = 0
			if Dialogue._has_box() and Dialogue.box.is_open():
				Input.action_press("interact")
				await get_tree().physics_frame
				Input.action_release("interact")
			await get_tree().physics_frame
		else:
			quiet += 1
			await get_tree().physics_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
