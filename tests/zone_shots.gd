extends Node
## Saves 2x screenshots of every zone in its story states with the hero in frame, for art and
## layout review. Needs a display (e.g. xvfb-run) and the GL renderer:
##
##   xvfb-run -a godot --rendering-driver opengl3 --path . res://tests/zone_shots.tscn -- --out=/some/dir
##
## Optional: --only=street_hale,store_aisles   --hero=female:2:bob

const SHOTS: Array[Dictionary] = [
	{"name": "street_hale", "zone": "street", "flags": ["C1_ERRAND", "C1_LAST_WORDS"], "at": Vector2(212, 500), "face": Vector2.UP},
	{"name": "street_walt", "zone": "street", "flags": ["C1_ERRAND", "C1_LAST_WORDS"], "at": Vector2(700, 560), "face": Vector2.RIGHT},
	{"name": "street_nine", "zone": "street", "flags": ["C1_ERRAND", "C1_LAST_WORDS"], "at": Vector2(1150, 600), "face": Vector2.LEFT},
	{"name": "street_okoro", "zone": "street", "flags": ["C1_ERRAND", "C1_LAST_WORDS"], "at": Vector2(1640, 580), "face": Vector2.UP},
	{"name": "street_store", "zone": "street", "flags": ["C1_ERRAND", "C1_LAST_WORDS"], "at": Vector2(2000, 500), "face": Vector2.UP},
	{"name": "street_chaos_wreck", "zone": "street", "flags": ["vanished"], "at": Vector2(1330, 566), "face": Vector2.DOWN},
	{"name": "street_chaos_okoro", "zone": "street", "flags": ["vanished"], "at": Vector2(1720, 590), "face": Vector2.LEFT},
	{"name": "house_bedroom", "zone": "house", "flags": [], "at": Vector2(150, 230), "face": Vector2.UP},
	{"name": "house_kitchen", "zone": "house", "flags": ["C1_ERRAND"], "at": Vector2(470, 280), "face": Vector2.UP},
	{"name": "house_living", "zone": "house", "flags": ["C1_ERRAND"], "at": Vector2(420, 560), "face": Vector2.UP},
	{"name": "house_foyer", "zone": "house", "flags": ["C1_ERRAND"], "at": Vector2(720, 560), "face": Vector2.UP},
	{"name": "house_kitchen_night", "zone": "house", "flags": ["vanished"], "at": Vector2(470, 280), "face": Vector2.UP},
	{"name": "store_entrance", "zone": "store", "flags": ["C1_ERRAND"], "at": Vector2(336, 440), "face": Vector2.UP},
	{"name": "store_aisles", "zone": "store", "flags": ["C1_ERRAND"], "at": Vector2(330, 262), "face": Vector2.UP},
	{"name": "store_back", "zone": "store", "flags": ["C1_ERRAND"], "at": Vector2(500, 150), "face": Vector2.UP},
	{"name": "store_after", "zone": "store", "flags": ["vanished", "wade_gone"], "at": Vector2(330, 262), "face": Vector2.UP},
]

var _out := ""
var _only: PackedStringArray = []
var _hero := ["female", 2, "bob"]


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
		elif arg.begins_with("--hero="):
			var parts := arg.trim_prefix("--hero=").split(":")
			_hero = [parts[0], int(parts[1]), parts[2]]
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	GameState.delete_save()
	var placeholder := Node.new()
	get_tree().root.add_child(placeholder)
	get_tree().current_scene = placeholder
	Router.start_new_game(_hero[0], _hero[1], _hero[2])
	while Router.game == null or Router.game.zone == null:
		await get_tree().process_frame
	await _settle()
	for shot: Dictionary in SHOTS:
		if not _only.is_empty() and not _only.has(shot["name"]):
			continue
		GameState.flags.load_dict({})
		for flag: String in shot["flags"]:
			GameState.flags.set_flag(flag)
		for entry: Variant in DB.zone(shot["zone"]).get("entities", []):
			if String((entry as Dictionary).get("kind", "")) == "trigger":
				GameState.flags.set_flag("done:" + String(entry.get("id", "")))
		await _settle()
		Router.game.load_zone(shot["zone"], "", shot["at"])
		Router.game.player.facing = shot["face"]
		Router.game.player.camera.reset_smoothing()
		for i in 40:
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		if image.get_width() < 1920:
			image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
		image.save_png(_out.path_join("%s.png" % shot["name"]))
		print("[shots] saved ", shot["name"])
	print("SHOTS DONE")
	AudioManager.shutdown()
	await get_tree().process_frame
	get_tree().quit()


## Lets the opening card and dialogue finish so nothing covers the screenshots.
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
