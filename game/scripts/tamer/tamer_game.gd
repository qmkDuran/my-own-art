class_name TamerGame
extends Node2D
## The trainer prototype: one generated meadow (Lanternfall's zone generator and view), the trainer, your team on
## the field, wild packs, the camp, and the opening meeting with the three starters. This node wires the pieces and
## routes a few events between them (a win grows bond, a wiped team retreats to camp). `TamerGame.current` is the one
## way the prototype's systems reach the field (the same documented service-locator pattern as Game.current).

static var current: TamerGame

const MOTES: int = 50
const MOTES_EXTENTS := Vector2(520, 300)
const VIEW_RADIUS: float = 560.0
const CAMP_STAND := Vector2(0, 40)
const ROOF_ROOM: float = 60.0
const ROUTE_REACH: float = 0.92         ## the last rival stands just short of the far clearing
const RIVAL_ROOM: float = 10.0
const CAMP_AWAY: float = 600.0
const ROUTE_STEP: float = 0.05
const RIVAL_CLEAR: float = 300.0
const FLASH_GAIN: float = 0.35          ## the meadow is daylit: hit lights only need to warm the ground

var layout: ZoneLayout
var nav: Nav
var world: Node2D
var fx_layer: Node2D
var trainer: Trainer
var camera: CameraRig
var team: Team
var guide := TamerGuide.new()
var field: TeamField
var battle: BattleMode
var hud: TamerHud
var input: TamerInput
var spawner: TamerSpawner
var camp: Camp
var lens: SyncLens
var meeting: StarterMeeting
var aim: AimPreview
var slow: SlowTime
var rivals: Array[RivalTrainer] = []
var retreating: bool = false            ## the team was wiped and the trainer is on the way back to camp


func _ready() -> void:
	current = self
	TamerData.ensure()
	TamerKeys.ensure()
	GameData.use_zone(String(TamerData.rule("zone")))
	FloatText.enabled = true
	layout = ZoneGen.make(GameData.biome, int(GameData.zone(GameData.zone_id)["seed"]))
	nav = Nav.new(layout)
	Overlay.create(self)
	_build_world()
	team = Team.new()
	_build_systems()
	_wire()
	_place_rivals()
	meeting = StarterMeeting.new()
	add_child(meeting)
	meeting.setup(self)
	meeting.picked.connect(func(_r: CreatureRecord) -> void: guide.done("pick"))


func _exit_tree() -> void:
	HitStop.set_base(1.0)
	if current == self:
		current = null


func _build_world() -> void:
	var view := ZoneView.new()
	add_child(view)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	view.build(layout, world)
	fx_layer = Node2D.new()
	fx_layer.z_index = Fx.FX_Z
	add_child(fx_layer)
	Fx.layer = fx_layer
	Fx.flash_gain = FLASH_GAIN
	var ambient := CanvasModulate.new()
	ambient.color = Atmosphere.ambient(GameData.biome)
	add_child(ambient)
	trainer = Trainer.new()
	trainer.position = layout.start + Vector2(0, 60)
	world.add_child(trainer)
	camp = Camp.new()
	world.add_child(camp)
	camp.setup(self, camp_point())


func _build_systems() -> void:
	field = TeamField.new()
	add_child(field)
	field.setup(self)
	hud = TamerHud.new()
	add_child(hud)
	hud.setup(self)
	Fx.screen = hud
	spawner = TamerSpawner.new()
	add_child(spawner)
	spawner.setup(self)
	battle = BattleMode.new()
	add_child(battle)
	battle.setup(self)
	camera = CameraRig.new()
	add_child(camera)
	camera.setup(battle.focus, layout.size_px(), -ROOF_ROOM)
	Fx.motes(camera, MOTES_EXTENTS, MOTES, Pal.c("glint", 0.8))
	spawner.spawn_all()
	aim = AimPreview.new()
	Overlay.layer.add_child(aim)                             # above the slow-time wash
	aim.clear()
	slow = SlowTime.new()
	add_child(slow)
	slow.setup(self)
	lens = SyncLens.new()
	fx_layer.add_child(lens)
	lens.setup(self)
	input = TamerInput.new()
	add_child(input)
	input.setup(self)


func _wire() -> void:
	spawner.defeated.connect(_on_defeated)
	lens.synced.connect(func(_r: CreatureRecord) -> void: guide.done("befriend"))
	camp.rested.connect(func() -> void:
		guide.done("camp")
		if not team.members.is_empty():
			hud.camp_panel.open())
	battle.started.connect(func() -> void: guide.done("battle"))


## A wild creature fainted: your creature out grows closer, and the fight step is done.
func _on_defeated(_c: Creature) -> void:
	guide.done("fight")
	if field.partner != null:
		field.partner.rec.add_bond(float(TamerData.rule("bond.per_win")))


## Every creature knocked out (the "white out"): the screen fades, you retreat to camp and the team recovers there.
## Gentle: you lose one of each material you carry, nothing else.
func white_out() -> void:
	retreating = true
	battle.end(false)
	var W: Dictionary = TamerData.rule("white_out")
	hud.fade(float(W["fade"]), float(W["hold"]), func() -> void:
		for id: String in team.materials:
			team.materials[id] = maxi(0, int(team.materials[id]) - int(W["lose"]))
		trainer.place(layout.free_spot_near(camp_point() + CAMP_STAND, trainer.hit_radius()))
		camera.reset_smoothing()
		team.rest()
		retreating = false
		hud.notice(String(W["text"])))


## Rival trainers stand along the route from the meadow to its farthest clearing (tamer.json "rivals").
func _place_rivals() -> void:
	var far: Vector2 = layout.start
	for cl: Dictionary in layout.clearings:
		var at: Vector2 = layout.center_of(cl["center"])
		if not bool(cl.get("secret", false)) and at.distance_to(layout.start) > far.distance_to(layout.start):
			far = at
	for d: Dictionary in TamerData.rule("rivals.trainers"):
		var f: float = float(d["route"]) * ROUTE_REACH
		while layout.start.lerp(far, f).distance_to(camp_point()) < CAMP_AWAY and f < ROUTE_REACH:
			f += ROUTE_STEP                                    # not at the camp: resting must stay peaceful
		var at: Vector2 = layout.free_spot_near(layout.start.lerp(far, f), RIVAL_ROOM)
		var r := RivalTrainer.new().setup(self, d, at)
		world.add_child(r)
		rivals.append(r)
		for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):  # no wild pack right on top of a rival
			if (n as Node2D).global_position.distance_to(at) < RIVAL_CLEAR:
				n.queue_free()


func camp_point() -> Vector2:
	var fires: Array[Dictionary] = layout.props_of("campfire")
	return fires[0]["pos"] if not fires.is_empty() else layout.start


func view_radius() -> float:
	return VIEW_RADIUS


func partner() -> Creature:
	return field.partner

