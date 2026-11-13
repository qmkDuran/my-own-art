class_name Main
extends Node3D
## Builds the cozy night town and wires it together: the night environment and moonlight, the ground and the
## Meshy town, the light budget, the player with camera and lantern, the townsfolk, fireflies, dust and rain,
## the weather, the ambience and the HUD. Everything gets what it needs through setup().

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
	if not DisplayServer.get_name() == "headless" and TestRunner.is_playing():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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
	town.build(AssetLibrary.new())


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
		person.setup(spec)
		townsfolk.append(person)
	add_child(Fireflies.new())
	var dust: CameraParticles = CameraParticles.dust()
	add_child(dust)
	dust.follow(camera_rig.camera)


func _build_weather() -> void:
	weather = Weather.new()
	rain_fall = CameraParticles.rain()
	add_child(rain_fall)
	rain_fall.follow(camera_rig.camera)
	ambience = Ambience.new()
	add_child(ambience)
	ambience.setup(town.fountain)
	weather.rain_mix_changed.connect(_on_rain_mix)
	add_child(weather)


func _on_rain_mix(mix: float) -> void:
	environment_node.set_rain(mix)
	moon.set_rain(mix)
	ambience.set_rain(mix)
	rain_fall.amount_ratio = mix
	rain_fall.emitting = mix > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_rain"):
		weather.toggle()
		hud.note("It starts to rain" if weather.raining else "The rain eases off")
