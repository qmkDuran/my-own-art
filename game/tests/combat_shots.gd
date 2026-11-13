extends Node
## --combat-shots --only=<stage> --out=<dir> (run with --fixed-fps 30 so timings are exact): stages one combat
## moment in the Gloomwood seen through the gameplay camera with the combat HUD, and saves <dir>/<name>.png (some
## stages save several frames). Stills only (no video). Needs a display (xvfb-run is fine).

const STAGES: Array[String] = ["overview", "primary", "heavy", "bomb", "ward", "swarm", "elite_break",
	"boss_telegraph", "super", "busy", "contrast"]
const GLADE: Vector3 = Vector3(88.0, 0.0, 6.0)
const EAST: float = -PI * 0.5
const PITCH: float = -0.12
const FRAME: float = 1.0 / 30.0
const OVERVIEW_EYE: Vector3 = Vector3(92.0, 18.0, 30.0)
const OVERVIEW_AT: Vector3 = Vector3(126.0, 0.0, -6.0)

var m: Main
var out: String = ""
var set: CombatSet


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var stage: String = TestRunner.arg_value("--only=")
	if not STAGES.has(stage):
		print("SHOT unknown ", stage)
		get_tree().quit(1)
		return
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().create_timer(0.5).timeout
	m = Main.current
	out = TestRunner.arg_value("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	set = CombatSet.new(m, self)
	m.hud.visible = false
	m.controller.enabled = false
	m.kit_input.enabled = false
	m.display.frame_cap = 0
	await call("_stage_" + stage)
	get_tree().quit()


func save(name_of_shot: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name_of_shot + ".png"))
	print("SHOT saved ", name_of_shot)


func frames(count: int) -> void:
	for index: int in count:
		await get_tree().process_frame


func seconds(time: float) -> void:
	await frames(int(time / FRAME))


func _stage_overview() -> void:
	m.combat_hud.visible = false
	var eye := Camera3D.new()
	eye.fov = 55.0
	m.add_child(eye)
	eye.look_at_from_position(OVERVIEW_EYE, OVERVIEW_AT)
	eye.current = true
	for lamps: Array in m.woods.lamps_of.values():
		for lamp: LampLight in lamps:
			lamp.relight()
	await set.place_player(GLADE, EAST, PITCH)
	await seconds(2.0)
	await save("mission_overview")


func _stage_primary() -> void:
	await set.place_player(GLADE, EAST, PITCH)
	var targets: Array[Enemy] = set.dummies(["mushroom_imp", "pumpkin_head", "mushroom_imp"], GLADE, 10.0, 0.5)
	await set.aim_at(targets[1])
	for frame: int in 14:
		m.kit.primary.trigger()
		await frames(1)
	await save("primary_aim")


func _stage_heavy() -> void:
	await set.place_player(GLADE, EAST, PITCH)
	var targets: Array[Enemy] = set.dummies(["pumpkin_head", "mushroom_imp"], GLADE, 11.0, 0.3)
	await set.aim_at(targets[0])
	m.kit.heavy.begin()
	await seconds(Tuning.number("combat", "heavy", "full_charge") + 0.2)
	await save("heavy_charge")
	m.kit.heavy.release()
	await frames(3)
	await save("heavy_release")
	await frames(5)
	await save("heavy_release_late")


func _stage_bomb() -> void:
	await set.place_player(GLADE, EAST, PITCH)
	var targets: Array[Enemy] = set.dummies(["mushroom_imp", "mushroom_imp", "pumpkin_head", "mushroom_imp"],
		GLADE, 12.0, 0.25)
	await set.aim_at(targets[1])
	m.kit.bomb.begin_aim()
	await seconds(0.5)
	await save("bomb_arc")
	var shell: BombShell = m.kit.bomb.release()
	await seconds(shell.arc.landing_time + 2.0 * FRAME)
	await save("bomb_burst")


func _stage_ward() -> void:
	await set.place_player(GLADE, EAST, PITCH)
	var shooters: Array[Enemy] = set.dummies(["lantern_moth", "lantern_moth"], GLADE, 9.0, 0.35)
	await set.aim_at(shooters[0])
	m.kit.ward.raise()
	var chest: Vector3 = EnemyBrain.player_chest_of(m.player)
	for shooter: Enemy in shooters:
		var from: Vector3 = shooter.look().muzzle()
		EnemyShot.fire(m.roster, from, from.direction_to(chest), 12.0, 10.0, 0.4, 0.75)
	await seconds((shooters[0].centre().distance_to(chest) - Tuning.number("combat", "ward", "radius")) / 12.0 -
		FRAME * 2.0)
	await save("ward_incoming")
	await frames(4)
	await save("ward_block")


func _stage_swarm() -> void:
	await set.place_player(GLADE, EAST, PITCH)
	var pack: Array[Enemy] = set.pack(GLADE + Vector3(15.0, 0.0, 0.0), 9)
	await seconds(0.6)
	await set.aim_at(pack[0])
	for frame: int in 14:
		m.kit.primary.trigger()
		await frames(1)
	await save("swarm")


func _stage_elite_break() -> void:
	await set.place_player(GLADE, EAST, PITCH)
	var elite: Array[Enemy] = set.dummies(["scarecrow_knight"], GLADE, 8.0, 0.0)
	await set.aim_at(elite[0])
	await save("elite_shield")
	m.kit.heavy.begin()
	await seconds(Tuning.number("combat", "heavy", "full_charge") + 0.1)
	m.kit.heavy.release()
	await frames(6)
	await save("elite_break")


func _stage_boss_telegraph() -> void:
	await set.boss_fight()
	m.kit.aim.lock(null)
	m.camera_rig.pitch -= 0.2
	await set.wait_for_telegraph(0.6)
	await save("boss_telegraph")
	await set.wait_for_telegraph(0.6)
	await save("boss_telegraph_2")


func _stage_super() -> void:
	await set.boss_fight()
	set.pack(set.arena_centre() + Vector3(-3.0, 0.0, 5.0), 6)
	m.kit.meter.add(SuperMeter.cost())
	await seconds(0.5)
	m.kit.sunrise.fire()
	var times: Array[float] = [0.25, 0.9, 1.6, 2.7, 4.4, 6.5]
	var elapsed: float = 0.0
	for index: int in times.size():
		await seconds(times[index] - elapsed)
		elapsed = times[index]
		await save("super_%d" % (index + 1))
	await seconds(0.8)
	await save("hud")


## A busy moment of the boss fight (phase two, adds, a swarm, magic flying), then the same frame without the
## player and the enemies, for the readability check.
func _stage_busy() -> void:
	await set.boss_fight()
	var boss: Enemy = m.roster.boss()
	boss.take_hit(Hit.new(boss.max_health * 0.55, "heavy", boss.centre()))
	set.pack(set.arena_centre() + Vector3(-4.0, 0.0, 6.0), 8)
	await seconds(2.0)
	m.kit.ward.raise()
	for frame: int in 20:
		m.kit.primary.trigger()
		await frames(1)
	await save("busy")
	set.freeze()
	m.roster.visible = false
	m.player.visible = false
	await frames(1)
	await save("busy_no_actors")


## The enemies against the woods with no magic in the air, and the same frame without them.
func _stage_contrast() -> void:
	await set.place_player(GLADE, EAST, PITCH)
	set.dummies(["mushroom_imp", "pumpkin_head", "lantern_moth", "scarecrow_knight", "mushroom_imp"], GLADE, 9.0,
		0.4)
	await seconds(1.5)
	m.combat_hud.visible = false
	set.freeze()
	await save("contrast_on")
	m.roster.visible = false
	await frames(1)
	await save("contrast_off")
