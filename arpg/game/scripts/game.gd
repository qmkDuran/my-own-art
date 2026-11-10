class_name Game
extends Node2D
## The zone: a ruined suburb street at night in the time of distress (Dan 12:1). Michael is sent in answer to
## prayer (Dan 10:12-13). Builds the world, wires the systems and turns input into Michael's commands.

const PICKUP_RADIUS: float = 22.0
const TARGET_RADIUS: float = 40.0
const INTRO_SECONDS: float = 7.0

var world: Node2D
var zone: Zone
var michael: Michael
var spawner: Spawner
var objective: PrayerObjective
var camera: Camera2D
var hud: Hud
var inventory_panel: InventoryPanel
var skill_panel: SkillPanel
var hosts_panel: HostsPanel
var pause_panel: PausePanel
var bot: DemoBot

var _attack_target: Demon
var _pickup_target: GroundItem
var _zone_caption: String = ""
var _intro_t: float = INTRO_SECONDS


func _ready() -> void:
	GameData.ensure()
	InputSetup.ensure()
	Overlay.create(self)
	world = Node2D.new()
	world.y_sort_enabled = true
	zone = Zone.new()
	add_child(zone)
	add_child(world)
	zone.build(world)
	michael = Michael.new()
	michael.position = SceneData.vec(GameData.zone["player_start"])
	world.add_child(michael)
	spawner = Spawner.new()
	add_child(spawner)
	spawner.setup(world, michael)
	objective = PrayerObjective.new()
	add_child(objective)
	objective.setup(world, michael, spawner)
	camera = Camera2D.new()
	var size: Vector2 = SceneData.vec(GameData.zone["size"])
	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	michael.add_child(camera)
	_build_ui()
	michael.prog.leveled.connect(_on_level)
	michael.struck_down.connect(func() -> void: hud.notice("Struck down"))
	michael.raised.connect(func() -> void: hud.caption("{be_strong}"))
	objective.caption.connect(hud.caption)
	objective.progressed.connect(func(a: int, t: int) -> void: hud.notice("Prayer answered  %d / %d   (+1 star)" % [a, t]))
	get_tree().create_timer(0.6).timeout.connect(hud.caption.bind("{heard}"))           # Dan 10:12, then Dan 12:1
	get_tree().create_timer(4.0).timeout.connect(hud.caption.bind("{michael_arise}"))
	Audio.play_music("night_music", -9.0, 2.5)
	Audio.loop_player(self, "night_wind", -14.0)
	if OS.get_cmdline_user_args().has("--demo"):
		bot = DemoBot.new()
		add_child(bot)
		bot.setup(self)


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	hud = Hud.new()
	ui.add_child(hud)
	hud.setup(michael, objective)
	inventory_panel = InventoryPanel.new()
	ui.add_child(inventory_panel)
	inventory_panel.setup(michael, Rect2(590, 54, 352, 392))
	skill_panel = SkillPanel.new()
	ui.add_child(skill_panel)
	skill_panel.setup(michael, Rect2(18, 54, 430, 392))
	hosts_panel = HostsPanel.new()
	ui.add_child(hosts_panel)
	hosts_panel.setup(michael, Rect2(200, 44, 560, 412))
	pause_panel = PausePanel.new()
	ui.add_child(pause_panel)
	pause_panel.setup()


func _on_level(level: int) -> void:
	hud.notice("Level %d" % level)
	hud.caption("{be_strong}")
	Audio.sfx("level_up", -4.0)
	SkillFx.ring(world, michael.global_position, 90.0, Color("fbff86"), 0.8)


func mouse_world() -> Vector2:
	return get_global_mouse_position()


func panels_open() -> bool:
	return inventory_panel.visible or skill_panel.visible or hosts_panel.visible


# ------------------------------------------------------------------ input
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if panels_open():
			for p: GamePanel in [inventory_panel, skill_panel, hosts_panel]:
				p.visible = false
		else:
			get_tree().paused = not get_tree().paused
			pause_panel.visible = get_tree().paused
		return
	if get_tree().paused or bot != null:
		return
	if event.is_action_pressed("inventory"):
		inventory_panel.toggle()
	elif event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).physical_keycode == KEY_K:
		skill_panel.toggle()
	elif event.is_action_pressed("tree"):
		hosts_panel.toggle()
	elif event.is_action_pressed("dodge"):
		michael.dodge()
	elif event.is_action_pressed("charge"):
		michael.skills.use("descent", mouse_world())
	elif event.is_action_pressed("strike"):
		_click(mouse_world())
	else:
		for i: int in 4:
			if event.is_action_pressed("skill_%d" % (i + 1)):
				michael.skills.use(GameData.skills["slots"][i + 2], mouse_world())


## Left click: an item label -> go and pick it up; an enemy -> attack it; open ground -> walk there
## (with WASD held, a click always strikes toward the mouse).
func _click(at: Vector2) -> void:
	_attack_target = null
	_pickup_target = null
	for n: Node in world.get_children():
		var g := n as GroundItem
		if g != null and g.label_rect().has_point(at):
			_pickup_target = g
			michael.move_to(g.global_position)
			return
	var d: Demon = demon_near(at, TARGET_RADIUS)
	if d != null:
		_attack_target = d
	elif InputSetup.move_vector() != Vector2.ZERO:
		michael.strike(at)
	else:
		michael.move_to(at)


func demon_near(at: Vector2, r: float) -> Demon:
	var best: Demon = null
	var bd: float = r
	for n: Node in get_tree().get_nodes_in_group("demons"):
		var d := n as Demon
		var dist: float = d.global_position.distance_to(at + Vector2(0, 24))
		if not d.dead and dist < bd:
			bd = dist
			best = d
	return best


func _physics_process(delta: float) -> void:
	_intro_t -= delta
	if bot == null:
		_drive_player()
	_follow_targets()
	_auto_pickup()
	var cap: String = zone.caption_at(michael.global_position)
	if cap != _zone_caption and _intro_t < 0.0:
		_zone_caption = cap
		if cap != "":
			hud.caption("{%s}" % cap)


func _drive_player() -> void:
	if get_tree().paused:
		return
	michael.set_move_dir(InputSetup.move_vector())
	if Input.is_action_pressed("strike") and not panels_open():
		if _attack_target == null and _pickup_target == null and InputSetup.move_vector() == Vector2.ZERO:
			var d: Demon = demon_near(mouse_world(), TARGET_RADIUS)
			if d != null:
				_attack_target = d
			else:
				michael.move_to(mouse_world())
		elif InputSetup.move_vector() != Vector2.ZERO:
			michael.strike(mouse_world())
	michael.aim_at(mouse_world())


## Walk to a clicked enemy and strike it when in reach.
func _follow_targets() -> void:
	if _attack_target != null:
		if not is_instance_valid(_attack_target) or _attack_target.dead:
			_attack_target = null
			return
		var reach: float = float(GameData.skill("strike")["radius"]) * 0.8
		if michael.global_position.distance_to(_attack_target.global_position) > reach:
			michael.move_to(_attack_target.global_position)
		else:
			michael.stop()
			michael.strike(_attack_target.global_position + Vector2(0, -16))


func _auto_pickup() -> void:
	for n: Node in world.get_children():
		var g := n as GroundItem
		if g == null or g.global_position.distance_to(michael.global_position) > PICKUP_RADIUS:
			continue
		if michael.inv.add(g.item):
			FloatText.spawn(world, g.global_position, g.item["name"], GameData.rarity_color(g.item["rarity"]))
			Audio.sfx("pickup", -8.0)
			if _pickup_target == g:
				_pickup_target = null
			g.queue_free()
