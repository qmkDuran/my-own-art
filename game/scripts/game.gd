class_name Game
extends Node2D
## One zone being played: builds it from its generated layout, puts the Lamplighter where he arrives (an exit he
## came through, a saved spot, or the zone's start), restores the character and the zone's state from Session,
## and wires the systems. Story moments are ZoneEvents; input is GameInput; screens are GameUi. `Game.current` is
## the one way systems reach the zone being played (documented service locator; set in _ready, cleared on exit).

static var current: Game

const SAVE_EVERY: float = 10.0
const MOTES: int = 60
const MOTES_EXTENTS := Vector2(520, 300)
const ROOF_ROOM: float = 120.0

var zone_id: String
var layout: ZoneLayout
var nav: Nav
var world: Node2D
var fx_layer: Node2D
var dark: CanvasModulate                 ## the zone's darkness (Noon and Eclipse change it for a moment)
var darkness: Color
var player: Player
var spawner: Spawner
var camera: CameraRig
var ui: GameUi
var hud: Hud
var input: GameInput
var events: ZoneEvents
var lamps: Array[Waylamp] = []
var exits: Array[ZoneExit] = []
var cocoon: Cocoon
var loop: TuesdayLoop                    ## set in the Town of One Tuesday
var event_target: Vector2 = Vector2.INF  ## where a scripted moment wants you (the tracker's "event" target)
var flags: Dictionary = {}               ## this zone's own flags (boss, boss_down)
var _dirty: bool = false
var _save_t: float = 0.0


func _ready() -> void:
	current = self
	GameData.ensure()
	InputSetup.ensure()
	if Session.zone_id == "":
		Session.reset()
	zone_id = Session.zone_id
	GameData.use_zone(zone_id)
	FloatText.enabled = bool(GameData.setting("damage_numbers", true))
	layout = ZoneGen.make(GameData.biome, int(GameData.zone(zone_id)["seed"]))
	nav = Nav.new(layout)
	Overlay.create(self)
	_build_world()
	_build_ui()
	if Dev.enabled():
		var dev := DevTools.new()
		add_child(dev)
		dev.setup(self)
	var guide := ObjectiveGuide.new()
	world.get_parent().add_child(guide)
	guide.setup(self)
	var mood := Atmosphere.new()
	add_child(mood)
	mood.setup(self)
	_restore()
	events = ZoneEvents.new()
	add_child(events)
	events.setup(self)
	if Session.campaign.step_index(Opening.QUEST) >= 0:
		var opening := Opening.new()
		add_child(opening)
		opening.setup(self)
	if GameData.biome.get("loop", false):
		loop = TuesdayLoop.new()
		add_child(loop)
		loop.setup(self)
	Session.campaign.notify("enter_zone", zone_id)
	Session.campaign.quest_done.connect(_on_quest_done)
	Session.campaign.changed.connect(mark_dirty)
	Audio.play_music(String(GameData.zone(zone_id)["music"]))
	Audio.set_reverb(bool(GameData.biome.get("reverb", false)))


func _exit_tree() -> void:
	Audio.set_muffled(false)
	if get_tree().node_added.is_connected(_standing):
		get_tree().node_added.disconnect(_standing)
	if current == self:
		Session.campaign.quest_done.disconnect(_on_quest_done)
		Session.campaign.changed.disconnect(mark_dirty)
		if SaveGame.enabled():
			SaveGame.write(self)
		current = null


func _build_world() -> void:
	get_tree().node_added.connect(_standing)
	var view := ZoneView.new()
	add_child(view)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	view.build(layout, world)
	fx_layer = Node2D.new()
	fx_layer.z_index = Fx.FX_Z
	add_child(fx_layer)
	dark = CanvasModulate.new()
	darkness = Atmosphere.ambient(GameData.biome)
	dark.color = darkness
	add_child(dark)
	player = Player.new()
	player.position = layout.start
	world.add_child(player)
	camera = CameraRig.new()
	add_child(camera)
	camera.setup(player, layout.size_px(), -ROOF_ROOM)
	Fx.motes(camera, MOTES_EXTENTS, MOTES, Pal.c(String(GameData.biome["ambient"].get("motes_color", "glint")), 0.8))
	spawner = Spawner.new()
	add_child(spawner)
	spawner.setup(world, layout, player)
	player.died_and_rose.connect(camera.reset_smoothing)
	_interactables()
	add_child(LabelStack.new())


func _build_ui() -> void:
	ui = GameUi.new()
	add_child(ui)
	ui.setup(self)
	hud = ui.hud
	input = GameInput.new()
	add_child(input)
	input.setup(self)


func _interactables() -> void:
	var by_kind: Dictionary = {"chest": Chest, "waylamp": Waylamp, "npc": Npc, "cocoon": Cocoon, "note": LoreObject,
		"cairn": LoreObject, "statue_fisher": LoreObject, "signpost": LoreObject, "exit": ZoneExit}
	for p: Dictionary in layout.props:
		if p["kind"] == "hunger":
			HungerZone.make(world, p["pos"], float(p.get("r", 150.0)))
			continue
		if p["kind"] == "updraft":
			Updraft.make(world, p["pos"], float(p.get("r", 70.0)))
			continue
		if p["kind"] == "lure":
			Lure.make(world, p["pos"], int(p.get("count", 3)))
			continue
		if not by_kind.has(p["kind"]) or not Dialogue.holds(p.get("when", {}), Session.campaign):
			continue
		var it: Interactable = (by_kind[p["kind"]] as GDScript).new().setup(p)
		world.add_child(it)
		if it is Waylamp:
			lamps.append(it)
		elif it is ZoneExit:
			exits.append(it)
		elif it is Cocoon:
			cocoon = it


## The character and this zone's state come back from Session; the Lamplighter stands where he arrives.
func _restore() -> void:
	if not Session.character.is_empty():
		SaveGame.apply_character(self, Session.character)
	SaveGame.apply_zone(self, Session.zone_state(zone_id))
	player.global_position = _arrival()
	player.respawn_at = _respawn_point()
	camera.reset_smoothing()
	_framing()


## Landmarks the camera leans toward, an arrival shot of the biggest one, and Tallow's passers-by.
func _framing() -> void:
	var view: Dictionary = GameData.biome.get("view", {})
	for f: Array in view.get("frames", []):
		camera.frames.append([Vector2(float(f[0]), float(f[1])), float(f[2]), float(f[3])])
	if Session.establishing and view.has("establish"):
		Session.establishing = false
		_establish(view["establish"])
	elif view.has("intro"):
		var at: Array = view["intro"]
		camera.intro(Vector2(float(at[0]), float(at[1])), float(at[2]))
	for w: Dictionary in GameData.biome.get("walkers", []):
		var pts: Array[Vector2] = []
		for q: Array in w["route"]:
			pts.append(Vector2(float(q[0]), float(q[1])))
		Walker.make(world, String(w["folk"]), pts)


## A new game opens in black on the Great Lantern, fades in, holds, and pans down to the Lamplighter with a caption.
func _establish(e: Dictionary) -> void:
	camera.establish(Vector2(float(e["at"][0]), float(e["at"][1])), float(e["hold"]), float(e["pan"]))
	ui.fade_in(float(e["fade"]))
	ui.letterbox(true)
	get_tree().create_timer(float(e["hold"]) + float(e["pan"]), false).timeout.connect(func() -> void:
		if is_instance_valid(ui):
			ui.letterbox(false))
	get_tree().create_timer(float(e["hold"]), false).timeout.connect(func() -> void:
		if is_instance_valid(hud):
			hud.caption(String(e["caption"])))


func _arrival() -> Vector2:
	if Session.arrive_at_lamp:
		for l: Waylamp in lamps:
			if l.lit:
				return l.stand_point()
	for e: ZoneExit in exits:
		if e.to == Session.arrive_from:
			return e.stand_point()
	if Session.position != Vector2.INF and layout.point_free(Session.position, player.radius):
		return Session.position
	return layout.start


## Where you wake if you fall: the lit waylamp nearest to where you arrived (else the arrival itself).
func _respawn_point() -> Vector2:
	var best: Vector2 = player.global_position
	var best_d: float = INF
	for l: Waylamp in lamps:
		var d: float = l.global_position.distance_to(player.global_position)
		if l.lit and d < best_d:
			best_d = d
			best = l.stand_point()
	return best


## 0 at the zone's start, 1 at the farthest point (drives enemy and loot level).
func progress_at(p: Vector2) -> float:
	return clampf(p.distance_to(layout.start) / layout.size_px().length() * 1.6, 0.0, 1.0)


func mark_dirty() -> void:
	_dirty = true


func start_boss() -> void:
	events.start_boss()


func _process(delta: float) -> void:
	_pay_rewards()
	_save_t -= delta
	if _dirty and _save_t <= 0.0 and SaveGame.enabled():
		_save_t = SAVE_EVERY
		_dirty = false
		SaveGame.write(self)


## Quest rewards: experience now, items at your feet.
func _pay_rewards() -> void:
	var c: Campaign = Session.campaign
	while not c.rewards.is_empty():
		var r: Dictionary = c.rewards.pop_front()
		player.prog.add_xp(float(r.get("xp", 0.0)))
		var items: Array = []
		if r.has("unique"):
			items.append(LootGen.make_unique(String(r["unique"]), player.prog.level))
		if r.has("set"):
			items.append_array(LootGen.set_pieces(String(r["set"])))
		var spots: Array[Vector2] = LootDrop.free_spots(layout, player.global_position, items.size(), player.global_position)
		for i: int in mini(items.size(), spots.size()):
			GroundItem.spawn(world, spots[i], items[i])


func _on_quest_done(id: String) -> void:
	hud.notice("Quest complete: " + String(GameData.quests[id]["title"]))
	Audio.sfx("level_up", -6.0, 1.2)
	if id == "moth_hollow":
		hud.messages.show_end_card()


## The world's darkness goes to `to` and comes back (Noon's daylight, Eclipse's deeper dark).
func shift_darkness(to: Color, hold: float, back: float) -> void:
	darkness = Atmosphere.ambient(GameData.biome)                # the Brightness setting may have changed
	var tw := create_tween()
	tw.tween_property(dark, "color", to, 0.12)
	tw.tween_interval(hold)
	tw.tween_property(dark, "color", darkness, back)


## Everything placed in the world (props, people, effects) stands up: the lantern lights it without shadows; only
## the ground (ZoneView, outside the world node) takes the lantern's shadows.
func _standing(n: Node) -> void:
	if n is CanvasItem and world != null and (world.is_ancestor_of(n) or (fx_layer != null and fx_layer.is_ancestor_of(n))):
		(n as CanvasItem).light_mask |= Fx.STANDING_MASK


func lit_lamps() -> int:
	return lamps.filter(func(l: Waylamp) -> bool: return l.lit).size()


## Guardian moths burn hostile shots that touch them.
func moth_guards_catch(at: Vector2) -> bool:
	for m: Node in get_tree().get_nodes_in_group("moth_guards"):
		if (m as Node2D).global_position.distance_to(at) < Moth.HIT_RADIUS * 2.0:
			Fx.halo(fx_layer, at, 16.0, Pal.c("flame", 0.8), 0.2)
			return true
	return false
