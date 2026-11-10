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
	var zoom: float = float(GameData.settings.get("camera_zoom", 1.5))
	camera.zoom = Vector2(zoom, zoom)
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
	inventory_panel.setup(michael, Rect2(590, 30, 352, 432))
	skill_panel = SkillPanel.new()
	ui.add_child(skill_panel)
	skill_panel.setup(michael, Rect2(18, 54, 430, 392))
	hosts_panel = HostsPanel.new()
	ui.add_child(hosts_panel)
	hosts_panel.setup(michael, Rect2(200, 44, 560, 412))
	pause_panel = PausePanel.new()
	ui.add_child(pause_panel)
	pause_panel.setup()
	var cursor := CursorView.new()
	ui.add_child(cursor)
	cursor.setup(self)


func _on_level(level: int) -> void:
	hud.notice("Level %d" % level)
	hud.caption("{be_strong}")
	Audio.sfx("level_up", -4.0)
	SkillFx.ring(world, michael.global_position, 90.0, Color("fbff86"), 0.8)


func panels_open() -> bool:
	return inventory_panel.visible or skill_panel.visible or hosts_panel.visible


# ------------------------------------------------------------------ input (click-to-move first)
## The pointer can be the mouse or, in the recorded demo, a virtual cursor the bot moves.
var cursor_override: Vector2 = Vector2.INF
var lmb: bool = false
var stand: bool = false


func mouse_world() -> Vector2:
	return cursor_override if cursor_override != Vector2.INF else get_global_mouse_position()


func cursor_screen() -> Vector2:
	return get_viewport().get_canvas_transform() * mouse_world()


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
	elif event.is_action_pressed("skills"):
		skill_panel.toggle()
	elif event.is_action_pressed("tree"):
		hosts_panel.toggle()
	elif event.is_action_pressed("dodge"):
		michael.dodge()
	elif event.is_action_pressed("charge"):
		press_skill("descent")
	elif event.is_action_pressed("click"):
		lmb_down()
	elif event.is_action_released("click"):
		lmb = false
	else:
		for i: int in 4:
			if event.is_action_pressed("skill_%d" % (i + 1)):
				press_skill(GameData.skills["slots"][i + 2])


func press_skill(id: String) -> void:
	if michael.skills.use(id, mouse_world()):
		hud.flash(id)


## Left button down: an item name -> go and pick it up; with Shift -> strike toward the cursor where you stand;
## an enemy -> go to it and strike; open ground -> walk there (keep holding to keep walking).
func lmb_down() -> void:
	lmb = true
	var at: Vector2 = mouse_world()
	_attack_target = null
	_pickup_target = null
	for n: Node in world.get_children():
		var g := n as GroundItem
		if g != null and g.label_rect().has_point(at):
			_pickup_target = g
			michael.move_to(g.global_position)
			return
	if stand:
		michael.stop()
		michael.strike(at)
		hud.flash("strike")
		return
	var d: Demon = demon_near(at, TARGET_RADIUS)
	if d != null:
		_attack_target = d
	else:
		michael.move_to(at)
		SkillFx.ring(world, at, 12.0, Color("fbff86"), 0.3)


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
		stand = Input.is_action_pressed("stand")
		if InputSetup.keyboard_movement:
			michael.set_move_dir(InputSetup.move_vector())
	_drive_pointer()
	_follow_targets()
	_auto_pickup()
	var cap: String = zone.caption_at(michael.global_position)
	if cap != _zone_caption and _intro_t < 0.0:
		_zone_caption = cap
		if cap != "":
			hud.caption("{%s}" % cap)


## While the left button is held: Shift -> keep striking toward the cursor without moving; otherwise keep walking
## toward the cursor (unless chasing an enemy or an item).
func _drive_pointer() -> void:
	if get_tree().paused or panels_open():
		return
	var at: Vector2 = mouse_world()
	michael.aim_at(at)
	if not lmb:
		return
	if stand:
		_attack_target = null
		michael.stop()
		if not michael.busy():
			michael.strike(at)
			hud.flash("strike")
	elif _attack_target == null and _pickup_target == null:
		michael.move_to(at)


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
			if not michael.busy():
				michael.strike(_attack_target.global_position + Vector2(0, -16))
				hud.flash("strike")


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
