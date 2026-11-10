extends Node
## Opens every scene and every zone in each story state, lets each run for a moment, then
## quits cleanly. Run headless and check the log has no ERROR / WARNING lines:
##
##   godot --headless --path . res://tests/smoke_test.tscn

const SCENES: Array[String] = [
	"res://scenes/boot/disclaimer.tscn",
	"res://scenes/menu/main_menu.tscn",
	"res://scenes/game/game.tscn",
]
const STATES: Array[Array] = [[], ["C1_ERRAND"], ["vanished"], ["vanished", "C1_DAWN"]]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var placeholder := Node.new()
	get_tree().root.add_child(placeholder)
	get_tree().current_scene = placeholder
	for scene: String in SCENES:
		print("[smoke] scene ", scene)
		get_tree().change_scene_to_file(scene)
		await _seconds(1.5)
	var menu_scene: PackedScene = load(SCENES[1])
	var menu := menu_scene.instantiate()
	get_tree().root.add_child(menu)
	menu.call("open_picker")
	menu.call("choose", "male", 0, "curly")
	await _seconds(0.5)
	menu.queue_free()
	await _wait_for_game()
	for zone_id: String in DB.zone_ids():
		for state: Array in STATES:
			GameState.flags.load_dict({})
			for flag: String in state:
				GameState.flags.set_flag(flag)
			print("[smoke] zone %s %s" % [zone_id, state])
			Router.game.load_zone(zone_id, "", null)
			await _seconds(0.6)
	print("SMOKE PASS")
	AudioManager.shutdown()
	for i in 5:
		await get_tree().process_frame
	get_tree().quit()


func _wait_for_game() -> void:
	while Router.game == null or Router.game.zone == null or Router.is_busy():
		await get_tree().process_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
