extends Node
## --shots --only=<name> --out=<dir>: stages one review still in the real game and saves it as <dir>/<name>.png.
## Stills only (no video). Needs a display (xvfb-run is fine).

const SHOTS: Array[String] = ["overview", "third_person", "lock_on", "spit_tree", "hiding", "searching",
	"ridge_fight", "hud_closeup"]
const OVERVIEW_EYE: Vector3 = Vector3(0, 46, 40)
const OVERVIEW_FOG_SHARE: float = 0.35
const HUD_TOP_SHARE: float = 0.12
const HUD_BOTTOM_SHARE: float = 0.3
const DUEL_DISTANCE: float = 8.0
const SIDE_VIEW: float = 0.7
const RIDGE_HIGH: float = 2.4

var stage: Stage
var finder: SpotFinder
var m: Main


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	Main.skip_intro = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().create_timer(0.5).timeout
	await get_tree().physics_frame
	m = Main.current
	stage = Stage.new(m)
	await stage.frames(5)
	finder = SpotFinder.new(m)
	stage.script_player()
	var shot: String = TestRunner.arg_value("--only=")
	assert(SHOTS.has(shot), "unknown shot " + shot)
	await call("_stage_" + shot)
	await stage.frames(3)
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	if shot == "hud_closeup":
		image = _hud_strips(image)
	var out: String = TestRunner.arg_value("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	image.save_png(out.path_join(shot + ".png"))
	print("SHOT saved ", shot)
	get_tree().quit()


func _stage_overview() -> void:
	m.hud.visible = false
	stage.freeze_bot()
	var eye := Camera3D.new()
	m.add_child(eye)
	eye.fov = 60.0
	eye.look_at_from_position(OVERVIEW_EYE, Vector3(0, 0, -2))
	eye.current = true
	var env: Environment = m.woods.find_children("*", "WorldEnvironment", true, false)[0].environment
	env.fog_density *= OVERVIEW_FOG_SHARE
	await stage.frames(20)


func _stage_third_person() -> void:
	stage.freeze_bot()
	stage.place(m.player, Vector2(-18, 18), m.woods.ground_at(Vector2(2, -1)))
	stage.place(m.bot, Vector2(3, -2), m.player.global_position)
	stage.camera_behind_player(-12.0)
	m.player.move_intent = m.player.forward()
	await stage.seconds(0.6)
	m.player.move_intent = Vector3.ZERO
	await stage.frames(4)


## Puts the player in a hiding spot where the bot cannot watch it go in (the bot looks away meanwhile).
func _hide_player(spot: Vector2, look: Vector3) -> void:
	stage.face(m.bot, m.bot.global_position * 2.0 - m.woods.ground_at(spot))
	stage.place(m.player, spot, look)
	await stage.frames(3)


## The bot in the open with the player facing it from DUEL_DISTANCE, camera behind the player.
func _duel_setup(bot_spot: Vector2) -> void:
	stage.freeze_bot()
	stage.place(m.bot, bot_spot, m.player.global_position)
	var player_spot: Vector2 = finder.open_view_spot(m.bot.global_position, DUEL_DISTANCE)
	stage.place(m.player, player_spot, m.bot.global_position)
	stage.face(m.bot, m.player.global_position)
	stage.camera_behind_player(-10.0)
	await stage.frames(10)


func _stage_lock_on() -> void:
	await _duel_setup(Stage.ground_xz(m.woods.patrol_points[1]))
	m.lock_on.toggle()
	m.bot.aim_point = m.player.chest_position()
	await stage.frames(30)
	m.bot.try_spit()
	await stage.seconds(0.5)


func _stage_spit_tree() -> void:
	stage.freeze_bot()
	var setup: Dictionary = finder.tree_shot(5.0, 2.5)
	stage.place(m.player, setup["shooter"], setup["tree"])
	stage.place(m.bot, setup["behind"], m.player.global_position)
	stage.camera_behind_player(-8.0)
	m.rig.yaw += SIDE_VIEW
	m.rig.snap()
	await stage.frames(10)
	m.player.aim_point = m.bot.chest_position()
	m.player.try_spit()
	await stage.seconds(Tuning.f("spit", "windup") + 0.9)


func _stage_hiding() -> void:
	stage.freeze_bot()
	var bush: HidingSpot = m.woods.hiding_spots[3]
	var bot_spot: Vector2 = finder.open_view_spot(bush.global_position, 8.0)
	stage.place(m.bot, bot_spot, m.player.global_position)
	await _hide_player(Stage.ground_xz(bush.global_position), m.bot.global_position)
	var away: Vector3 = (m.bot.global_position - m.player.global_position).rotated(Vector3.UP, 1.2)
	stage.camera_behind_player(-16.0)
	m.brain.mover.go_to(m.bot.global_position + away.normalized() * 6.0, true)
	await stage.seconds(1.2)


func _stage_searching() -> void:
	stage.freeze_bot()
	var bush: HidingSpot = m.woods.hiding_spots[3]
	var bot_spot: Vector2 = finder.open_view_spot(bush.global_position, 10.0)
	var away: Vector2 = (bot_spot - Stage.ground_xz(bush.global_position)).normalized()
	stage.place(m.bot, bot_spot + away * 2.0, m.player.global_position)
	await _hide_player(Stage.ground_xz(bush.global_position), m.bot.global_position)
	stage.camera_behind_player(-14.0)
	m.brain.active = true
	m.brain.senses.note_clue(m.bot.global_position)
	m.brain.change_state("search")
	await stage.seconds(1.8)


func _stage_ridge_fight() -> void:
	stage.freeze_bot()
	var crest := Vector2(14.6, -16.4)
	stage.place(m.player, crest, m.player.global_position)
	var bot_spot: Vector2 = _ridge_spot(crest, 7.5)
	stage.place(m.bot, bot_spot, m.player.global_position)
	stage.face(m.player, m.bot.global_position)
	stage.camera_behind_player(-14.0)
	await stage.frames(10)
	m.lock_on.toggle()
	m.player.aim_point = m.bot.chest_position()
	m.player.try_spit()
	await stage.seconds(Tuning.f("spit", "windup") + 0.3)
	m.bot.aim_point = m.player.chest_position()
	m.bot.try_spit()
	await stage.seconds(0.4)


## A spot on the ridge's high ground, `distance` from `from`, with a clear line of sight to it.
func _ridge_spot(from: Vector2, distance: float) -> Vector2:
	var chest: Vector3 = Vector3.UP * Tuning.f("perception", "chest_height")
	for k: int in 32:
		var spot: Vector2 = from + Vector2.from_angle(TAU * k / 32.0) * distance
		var high: bool = m.woods.shape.ridge_lift(spot) > RIDGE_HIGH
		if high and Sight.clear(m.get_world_3d(), m.woods.ground_at(from) + chest, m.woods.ground_at(spot) + chest):
			return spot
	return from + Vector2(distance, 0)


func _stage_hud_closeup() -> void:
	await _duel_setup(Stage.ground_xz(m.woods.patrol_points[1]))
	m.lock_on.toggle()
	m.brain.active = true
	m.player.health.hurt(26.0)
	m.bot.health.hurt(38.0)
	m.player.spit.start()
	await stage.seconds(Tuning.f("spit", "windup") + 0.6)
	m.player.dodge.cooldown_left = Tuning.f("dodge", "cooldown") * 0.6
	m.player.trap.cooldown_left = Tuning.f("trap", "cooldown") * 0.8


## The top band (Thornback's bar) above the bottom band (life, moves, stealth eye), as one picture.
func _hud_strips(image: Image) -> Image:
	var width: int = image.get_width()
	var top: int = int(image.get_height() * HUD_TOP_SHARE)
	var bottom: int = int(image.get_height() * HUD_BOTTOM_SHARE)
	var strips := Image.create(width, top + bottom, false, image.get_format())
	strips.blit_rect(image, Rect2i(0, 0, width, top), Vector2i.ZERO)
	strips.blit_rect(image, Rect2i(0, image.get_height() - bottom, width, bottom), Vector2i(0, top))
	return strips
