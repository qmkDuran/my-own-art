class_name Main
extends Node3D
## Builds the cozy night town and wires it together: the night environment and moonlight, the ground and the
## Meshy town, the Gloomwood beyond the gate, the light budget, the player with camera and lantern, the townsfolk,
## fireflies, dust and rain, the weather, the ambience and music, the Lamplighter's combat kit, the enemies, the
## mission and the HUDs. Everything gets what it needs through setup().

static var current: Main

var environment_node: NightEnvironment
var moon: Moonlight
var town: TownBuilder
var player: Player
var camera_rig: CameraRig
var controller: PlayerController
var townsfolk: Array[Townsperson] = []
var weather: Weather
var budget: LightBudget
var hud: Hud
var rain_fall: CameraParticles
var ambience: Ambience
var woods: MissionDecor
var roster: Roster
var fx: CombatFx
var health: PlayerHealth
var kit: LamplighterKit
var kit_input: KitInput
var mission: Mission
var music: MusicDirector
var combat_hud: CombatHud
var library: AssetLibrary
var graphics: GraphicsSettings
var vfx: VfxKit
var display: DisplaySettings
var fly: FlyCamera
var perf_overlay: PerfOverlay


func _ready() -> void:
	current = self
	InputSetup.install()
	_build_world()
	_build_player()
	_build_life()
	_build_weather()
	hud = Hud.new()
	add_child(hud)
	hud.setup()
	_build_combat()
	display = DisplaySettings.new()
	add_child(display)
	display.setup()
	display.changed.connect(hud.note)
	graphics = GraphicsSettings.new()
	add_child(graphics)
	graphics.setup(environment_node.environment, moon, budget, vfx.quota)
	graphics.apply(display.tier)
	graphics.changed.connect(func(tier: String) -> void:
		hud.note("Graphics: " + tier.capitalize())
		display.remember_tier(tier))
	_build_tools()
	if not DisplayServer.get_name() == "headless" and TestRunner.is_playing():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Fly mode (F1) and the performance overlay (F3).
func _build_tools() -> void:
	fly = FlyCamera.new()
	add_child(fly)
	fly.setup(camera_rig.camera, controller)
	fly.toggled.connect(func(flying: bool) -> void:
		hud.visible = not flying
		combat_hud.visible = not flying
		kit_input.enabled = not flying)
	perf_overlay = PerfOverlay.new()
	add_child(perf_overlay)
	perf_overlay.setup(display, graphics)


func _build_world() -> void:
	environment_node = NightEnvironment.new()
	add_child(environment_node)
	environment_node.setup()
	moon = Moonlight.new()
	add_child(moon)
	moon.setup()
	var ground := GroundBuilder.new()
	add_child(ground)
	ground.build()
	town = TownBuilder.new()
	add_child(town)
	library = AssetLibrary.new()
	town.build(library)
	var outskirts := Outskirts.new()
	add_child(outskirts)
	outskirts.build(library)
	var ground_of_woods := MissionGround.new()
	add_child(ground_of_woods)
	ground_of_woods.build(library)
	woods = MissionDecor.new()
	add_child(woods)
	woods.build(library)
	town.lights.append_array(woods.lights)


func _build_player() -> void:
	var start: Dictionary = Tuning.doc("town")["player_start"]
	var yaw: float = deg_to_rad(float(start["yaw_deg"]))
	player = Player.new()
	add_child(player)
	player.setup(Tuning.point(start["at"]), yaw)
	camera_rig = CameraRig.new()
	add_child(camera_rig)
	camera_rig.setup(player, yaw)
	controller = PlayerController.new()
	add_child(controller)
	controller.setup(player, camera_rig)
	budget = LightBudget.new()
	add_child(budget)
	budget.setup(town.lights, camera_rig.camera)


func _build_life() -> void:
	for spec: Dictionary in Tuning.doc("npcs")["townsfolk"]:
		var person := Townsperson.new()
		add_child(person)
		person.setup(spec, _benches())
		townsfolk.append(person)
	add_child(Fireflies.new())
	var dust: CameraParticles = CameraParticles.dust()
	add_child(dust)
	dust.follow(camera_rig.camera)


func _benches() -> Array[Node3D]:
	var out: Array[Node3D] = []
	out.assign(town.placed.filter(func(node: Node3D) -> bool: return node.get_meta("asset", "") == "bench"))
	return out


func _build_weather() -> void:
	weather = Weather.new()
	rain_fall = CameraParticles.rain()
	add_child(rain_fall)
	rain_fall.follow(camera_rig.camera)
	ambience = Ambience.new()
	add_child(ambience)
	ambience.setup(town.fountain, camera_rig.camera)
	weather.rain_mix_changed.connect(_on_rain_mix)
	add_child(weather)


## The combat: the effects kit, health, the enemies, the Lamplighter's kit and its controls, the mission in the
## Gloomwood, the music and the combat HUD.
func _build_combat() -> void:
	vfx = VfxKit.new()
	add_child(vfx)
	vfx.setup(camera_rig.camera)
	fx = CombatFx.new()
	add_child(fx)
	fx.setup(vfx)
	health = PlayerHealth.new()
	add_child(health)
	health.setup(player)
	roster = Roster.new()
	add_child(roster)
	roster.setup(library, player, health, fx)
	kit = LamplighterKit.new()
	add_child(kit)
	kit.setup(player, camera_rig, roster, fx, health, environment_node)
	kit_input = KitInput.new()
	add_child(kit_input)
	kit_input.setup(kit)
	music = MusicDirector.new()
	add_child(music)
	music.setup()
	mission = Mission.new()
	add_child(mission)
	mission.setup(roster, player, health, woods, music)
	combat_hud = CombatHud.new()
	add_child(combat_hud)
	combat_hud.setup(kit, mission)


func _on_rain_mix(mix: float) -> void:
	environment_node.set_rain(mix)
	moon.set_rain(mix)
	ambience.set_rain(mix)
	rain_fall.amount_ratio = mix
	rain_fall.emitting = mix > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("graphics"):
		graphics.cycle()
	elif event.is_action_pressed("frame_cap"):
		display.cycle_frame_cap()
	elif event.is_action_pressed("vsync"):
		display.toggle_vsync()
	elif event.is_action_pressed("render_driver"):
		display.toggle_windows_driver()
	elif event.is_action_pressed("fly"):
		fly.toggle()
	elif event.is_action_pressed("perf_overlay"):
		perf_overlay.toggle()
	elif event.is_action_pressed("fullscreen"):
		display.toggle_fullscreen()
	elif event.is_action_pressed("toggle_rain"):
		weather.toggle()
		hud.note("It starts to rain" if weather.raining else "The rain eases off")
