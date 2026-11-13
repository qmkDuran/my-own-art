extends Node
## --shots --only=<name> --out=<dir>: stages one review still in the real game and saves it as <dir>/<name>.png.
## Stills only (no video). Needs a display (xvfb-run is fine). An unknown shot name quits with an error.

const SHOTS: Array[String] = ["forest", "third_person", "loadout", "burrow", "ledge_jump", "sense_reveal",
	"burning_grass", "bot_hidden", "lock_on", "hud_closeup", "mind_overlay"]
const OVERVIEW_EYE: Vector3 = Vector3(6, 58, 52)
const OVERVIEW_LOOK: Vector3 = Vector3(0, 0, -4)
const OVERVIEW_FOG_SHARE: float = 0.35
const HUD_TOP_SHARE: float = 0.12
const HUD_BOTTOM_SHARE: float = 0.3
const DUEL_DISTANCE: float = 8.0
const KIT: Array[String] = ["snap", "cinder_spit", "leap", "echo_pulse"]

var stage: Stage
var finder: SpotFinder
var m: Main


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var shot: String = TestRunner.arg_value("--only=")
	if not SHOTS.has(shot):
		print("SHOT unknown ", shot)
		get_tree().quit(1)
		return
	Main.skip_intro = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().create_timer(0.5).timeout
	await get_tree().physics_frame
	m = Main.current
	stage = Stage.new(m)
	finder = SpotFinder.new(m)
	stage.script_player()
	stage.freeze_bot()
	stage.kit(m.player, KIT)
	m.hud.show_moves(m.player)
	await stage.frames(5)
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


func _stage_forest() -> void:
	m.hud.visible = false
	var eye := Camera3D.new()
	m.add_child(eye)
	eye.fov = 60.0
	eye.look_at_from_position(OVERVIEW_EYE, OVERVIEW_LOOK)
	eye.current = true
	var env: Environment = m.woods.find_children("*", "WorldEnvironment", true, false)[0].environment
	env.fog_density *= OVERVIEW_FOG_SHARE
	await stage.frames(20)


## Down at creature height: ferns, flowers and the pond ahead.
func _stage_third_person() -> void:
	var pond: Vector3 = m.woods.ground_at(Tuning.vec2(Tuning.woods["pond"]["pos"]))
	stage.place(m.player, Stage.ground_xz(pond) + Vector2(10.0, -2.0), pond)
	stage.place(m.bot, Stage.ground_xz(pond) + Vector2(-4.0, -6.0), m.player.global_position)
	stage.camera_behind_player(-10.0)
	m.player.move_intent = m.player.forward()
	await stage.seconds(0.5)
	m.player.move_intent = Vector3.ZERO
	await stage.frames(10)


func _stage_loadout() -> void:
	stage.camera_behind_player(-12.0)
	m.flow.begin(true)
	await stage.frames(5)


## The player burrowed in soft soil, creeping toward Thornback: back above ground, dust trail behind.
func _stage_burrow() -> void:
	stage.kit(m.player, ["snap", "burrow", "leap", "echo_pulse"])
	m.hud.show_moves(m.player)
	var soil: Vector3 = m.woods.soft_spot_near(m.woods.ground_at(Vector2(-8, 14)), 1.0)
	stage.place(m.player, Stage.ground_xz(soil) + Vector2(2.0, 1.0), soil + Vector3(-6, 0, -3))
	stage.place(m.bot, Stage.ground_xz(soil) + Vector2(-7.0, -4.0), m.player.global_position)
	stage.camera_behind_player(-24.0)
	await stage.frames(5)
	stage.use(m.player, "burrow")
	await stage.seconds(Stage.move_number("burrow", "windup") + 0.1)
	m.player.move_intent = (soil - m.player.global_position).normalized() * Vector3(1, 0, 1)
	await stage.seconds(1.0)
	m.player.move_intent = Vector3.ZERO
	await stage.frames(3)


## Mid-leap onto the plateau's rim, seen through the usual follow camera.
func _stage_ledge_jump() -> void:
	var jump: Dictionary = m.woods.features.jump_spots()[1]
	stage.place(m.player, Stage.ground_xz(jump["from"]), jump["to"])
	stage.camera_behind_player(-6.0)
	await stage.frames(5)
	var toward: Vector3 = (jump["to"] as Vector3) - m.player.global_position
	m.player.move_intent = Vector3(toward.x, 0.0, toward.z).normalized()
	var used: bool = stage.use(m.player, "leap")
	await stage.seconds(Stage.move_number("leap", "windup") + 0.2)
	assert(used)


## Thornback hidden in a bush; the player's Echo Pulse lights it up.
func _stage_sense_reveal() -> void:
	await _bot_in_bush(DUEL_DISTANCE)
	stage.use(m.player, "echo_pulse")
	await stage.seconds(Stage.move_number("echo_pulse", "windup") + 0.25)


func _stage_burning_grass() -> void:
	var patch: HidingSpot = _grass_patch()
	var spot: Vector2 = finder.open_view_spot(patch.global_position, patch.radius + 5.0)
	stage.place(m.player, spot, patch.global_position)
	stage.camera_behind_player(-12.0)
	m.player.aim_point = patch.global_position + Vector3.UP * 0.5
	await stage.frames(3)
	stage.use(m.player, "cinder_spit")
	await stage.seconds(Stage.move_number("cinder_spit", "windup") + 1.4)


## Thornback is crouched in that bush, right ahead: nothing gives it away.
func _stage_bot_hidden() -> void:
	await _bot_in_bush(6.5)
	await stage.frames(10)


## Thornback slips into a bush while the player is far away, then the player walks up to look at it.
func _bot_in_bush(distance: float) -> void:
	var bush: HidingSpot = m.woods.hiding_spots[3]
	var spot: Vector2 = finder.open_view_spot(bush.global_position, distance)
	stage.place(m.player, spot + Vector2(DUEL_DISTANCE, 0) * 3.0, bush.global_position)
	stage.place(m.bot, Stage.ground_xz(bush.global_position), m.woods.ground_at(spot))
	await stage.frames(3)
	stage.place(m.player, spot, bush.global_position)
	stage.camera_behind_player(-10.0)
	await stage.frames(3)


func _stage_lock_on() -> void:
	await _duel_setup()
	m.lock_on.toggle()
	m.bot.aim_point = m.player.chest_position()
	await stage.frames(30)
	stage.use(m.bot, "mud_lob")
	await stage.seconds(0.45)


func _stage_hud_closeup() -> void:
	await _duel_setup()
	m.lock_on.toggle()
	m.player.health.hurt(26.0)
	m.bot.health.hurt(38.0)
	m.player.effects.add("speed", 1.3, 4.0)
	m.player.moves[1].cooldown_left = 1.8
	m.player.roll.cooldown_left = 1.2
	await stage.frames(20)


## F3 on while the bot searches for a player it has learned likes this bush.
func _stage_mind_overlay() -> void:
	var bush: HidingSpot = m.woods.hiding_spots[3]
	for k: int in 3:
		m.model.note_hide(bush)
	var bot_spot: Vector2 = finder.open_view_spot(bush.global_position, 10.0)
	var away: Vector2 = (bot_spot - Stage.ground_xz(bush.global_position)).normalized()
	stage.place(m.bot, bot_spot + away * 2.0, m.player.global_position)
	stage.face(m.bot, m.bot.global_position + Vector3(away.x, 0, away.y))
	stage.place(m.player, Stage.ground_xz(bush.global_position), m.woods.ground_at(bot_spot))
	await stage.frames(3)
	stage.camera_behind_player(-14.0)
	m.brain.active = true
	m.brain.senses.note_clue(m.bot.global_position)
	m.brain.change_state("search")
	m.overlay.toggle()
	await stage.seconds(1.8)


## Thornback in the open with the player facing it from DUEL_DISTANCE, camera behind the player.
func _duel_setup() -> void:
	var bot_spot: Vector2 = Stage.ground_xz(m.woods.patrol_points[1])
	stage.place(m.bot, bot_spot, m.player.global_position)
	var player_spot: Vector2 = finder.open_view_spot(m.bot.global_position, DUEL_DISTANCE)
	stage.place(m.player, player_spot, m.bot.global_position)
	stage.face(m.bot, m.player.global_position)
	stage.camera_behind_player(-10.0)
	await stage.frames(10)


func _grass_patch() -> HidingSpot:
	for spot: HidingSpot in m.woods.hiding_spots:
		if spot.kind == "grass" and finder.open_view_spot(spot.global_position, spot.radius + 5.0) != Vector2.INF:
			return spot
	return null


## The top band (Thornback's bar) above the bottom band (life, moves, stealth eye), as one picture.
func _hud_strips(image: Image) -> Image:
	var width: int = image.get_width()
	var top: int = int(image.get_height() * HUD_TOP_SHARE)
	var bottom: int = int(image.get_height() * HUD_BOTTOM_SHARE)
	var strips := Image.create(width, top + bottom, false, image.get_format())
	strips.blit_rect(image, Rect2i(0, 0, width, top), Vector2i.ZERO)
	strips.blit_rect(image, Rect2i(0, image.get_height() - bottom, width, bottom), Vector2i(0, top))
	return strips
