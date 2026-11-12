class_name TamerGame
extends Node2D
## The demo: the Gate Hall (where it starts), the route (a generated meadow with wild creatures, a rival, the camp)
## and battle arenas, each its own place in the world; one is active at a time (AreaSwitch moves you between them).
## This node builds and wires the pieces and routes the events between them (a battle won, a team wiped).
## `TamerGame.current` is the one way the demo's systems reach the field (the documented service-locator pattern of
## Game.current); `layout`, `nav` and `world` are always the active place's.

static var current: TamerGame

const MOTES: int = 30
const MOTES_EXTENTS := Vector2(520, 300)
const VIEW_RADIUS: float = 560.0
const FLASH_GAIN: float = 0.35          ## daylight: hit lights only need to warm the ground

var route_layout: ZoneLayout
var route_nav: Nav
var route_root: Node2D
var route_view: ZoneView
var layout: ZoneLayout                  ## the active place's
var nav: Nav
var world: Node2D
var area: String = ""                   ## hall, route or arena
var hall: GateHall
var arena: Arena
var fx_layer: Node2D
var trainer: Trainer
var camera: CameraRig
var focus: Node2D
var ambient: CanvasModulate
var team: Team
var guide := TamerGuide.new()
var field: TeamField
var battle: ArenaBattle
var hud: TamerHud
var input: TamerInput
var spawner: TamerSpawner
var camp: Camp
var lens: SyncLens
var aim: AimPreview
var transition: Transition
var areas: AreaSwitch
var rivals: Array[RivalTrainer] = []
var view_shift := Vector2.ZERO         ## the arena camera sits this much low, so the cards don't cover the arena
var retreating: bool = false            ## the team was wiped and you are on the way back


func _ready() -> void:
	current = self
	TamerData.ensure()
	TamerKeys.ensure()
	GameData.use_zone(String(TamerData.rule("zone")))
	FloatText.enabled = true
	Overlay.create(self)
	_build_route()
	_build_systems()
	team = Team.new()
	_build_ui()
	hall = GateHall.new().build(self)
	add_child(hall)
	areas.go_hall_start()


func _exit_tree() -> void:
	HitStop.set_base(1.0)
	if current == self:
		current = null


func _build_route() -> void:
	route_layout = ZoneGen.make(GameData.biome, int(GameData.zone(GameData.zone_id)["seed"]))
	route_nav = Nav.new(route_layout)
	route_view = ZoneView.new()
	add_child(route_view)
	route_root = Node2D.new()
	route_root.y_sort_enabled = true
	add_child(route_root)
	route_view.build(route_layout, route_root)
	fx_layer = Node2D.new()
	fx_layer.z_index = Fx.FX_Z
	add_child(fx_layer)
	Fx.layer = fx_layer
	Fx.flash_gain = FLASH_GAIN
	ambient = CanvasModulate.new()
	add_child(ambient)
	trainer = Trainer.new()
	route_root.add_child(trainer)
	camp = Camp.new()
	route_root.add_child(camp)
	camp.setup(self, camp_point())
	route_root.add_child(HallDoor.new().setup(self, route_layout.start))


func _build_systems() -> void:
	transition = Transition.new()
	add_child(transition)
	areas = AreaSwitch.new()
	add_child(areas)
	areas.setup(self)
	focus = Node2D.new()
	add_child(focus)
	camera = CameraRig.new()
	add_child(camera)
	camera.setup(focus, route_layout.size_px(), 0.0)
	Fx.motes(camera, MOTES_EXTENTS, MOTES, Pal.c("gold", 0.8))
	battle = ArenaBattle.new()
	add_child(battle)
	battle.setup(self)


func _build_ui() -> void:
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
	spawner.spawn_all()
	_place_rivals()
	aim = AimPreview.new()
	Overlay.layer.add_child(aim)
	aim.clear()
	lens = SyncLens.new()
	fx_layer.add_child(lens)
	lens.setup(self)
	input = TamerInput.new()
	add_child(input)
	input.setup(self)
	camp.rested.connect(func() -> void:
		if not team.members.is_empty():
			hud.camp_panel.open())
	lens.synced.connect(func(_r: CreatureRecord) -> void: guide.done("sync"))


## Rival trainers stand along the route toward its farthest clearing, away from the camp (tamer.json "battle").
func _place_rivals() -> void:
	var z: ZoneLayout = route_layout
	var far: Vector2 = z.start
	for cl: Dictionary in z.clearings:
		var at: Vector2 = z.center_of(cl["center"])
		if not bool(cl.get("secret", false)) and at.distance_to(z.start) > far.distance_to(z.start):
			far = at
	var d: Dictionary = TamerData.rule("battle.trainers.ivo")
	var at: Vector2 = z.free_spot_near(z.start.lerp(far, float(d["route"])), RivalTrainer.ROOM)
	var r := RivalTrainer.new().setup(self, d, at)
	route_root.add_child(r)
	rivals.append(r)
	spawner.clear_near(at, RivalTrainer.CLEAR)


func camp_point() -> Vector2:
	var fires: Array[Dictionary] = route_layout.props_of("campfire")
	return fires[0]["pos"] if not fires.is_empty() else route_layout.start


## Does something at `p` stop a projectile? (cover and walls in an arena, blocked ground elsewhere)
func blocks_shot(p: Vector2) -> bool:
	if arena != null and area == "arena":
		return arena.layout.blocks_shot(p)
	return not layout.walkable(layout.cell_of(p))


func view_radius() -> float:
	return VIEW_RADIUS


func partner() -> Creature:
	return field.partner


## You walked into a wild creature on the route: a 1v1 in the arena that suits the ground (the meadow).
func encounter(c: Creature) -> void:
	if battle.on or transition.busy or field.partner == null or team.all_out():
		return
	battle.start_wild(c.rec, String(TamerData.rule("battle.route_arena")), String(TamerData.rule("battle.route_tier")), c)


## F1 (dev): a shiny. On the route one appears beside you; in the Gate Hall it waits in the meadow arena.
func dev_shiny() -> void:
	if battle.on:
		return
	if area == "route":
		spawner.spawn_shiny_near(trainer.global_position)
		return
	var kind: String = String(TamerData.rule("spawn.showcase_shiny"))
	var lvl: int = team.current().level if team.current() != null else 5
	battle.start_wild(CreatureRecord.make(kind, lvl, true, true), "meadow", hall.tier_id())


func go_route() -> void:
	guide.done("route")
	transition.play(func() -> void: areas.enter_route(route_layout.free_spot_near(route_layout.start + Vector2(0, 60), 8.0)))


func go_hall() -> void:
	transition.play(func() -> void: areas.enter_hall(hall.spot("you")))


func enter_arena(a: Arena) -> void:
	arena = a
	areas.enter_arena(a)


func return_to(where: String, at: Vector2) -> void:
	arena = null
	if where == "route":
		areas.enter_route(at)
	else:
		areas.enter_hall(at)
	if retreating:
		_after_loss(where)


## A trainer battle is over: a route rival remembers it.
func battle_over_with_trainer(opp: OpponentTrainer, won: bool) -> void:
	for r: RivalTrainer in rivals:
		if r.opponent == opp:
			r.finish(won)


## Your whole team is down: the battle is lost; back where you were, the team recovers (on the route, at camp,
## for one of each material).
func team_wiped() -> void:
	retreating = true
	if battle.on:
		battle.end(false)
	else:
		_after_loss(area)


func _after_loss(where: String) -> void:
	retreating = false
	team.rest()
	if where != "route":
		return
	var W: Dictionary = TamerData.rule("white_out")
	for id: String in team.materials:
		team.materials[id] = maxi(0, int(team.materials[id]) - int(W["lose"]))
	areas.enter_route(route_layout.free_spot_near(camp_point() + Vector2(0, 40), trainer.hit_radius()))
	hud.notice(String(W["text"]))


func _process(_delta: float) -> void:
	focus.global_position = arena.center() + view_shift if area == "arena" and arena != null else trainer.global_position
