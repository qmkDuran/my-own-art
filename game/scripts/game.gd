class_name Game
extends Node2D
## One play session in a zone: builds the world from the generated layout, wires the systems together, and keeps
## the story beats of the Glasswood slice (ambush at the gate, waylamps, the Glazier, Nim). Input is turned into
## commands by GameInput; the HUD and panels live in GameUi. `Game.current` is the one way systems reach the
## session (documented service locator; set in _ready, cleared on exit).

static var current: Game

const ZONE_SEED: int = 1000
const SAVE_EVERY: float = 10.0
const BOSS_TRIGGER: float = 300.0
const AMBUSH_DELAY: float = 2.5
const DARK_TIP_LIGHT: float = 40.0
const MOTES: int = 60
const MOTES_EXTENTS := Vector2(520, 300)
const ROOF_ROOM: float = 120.0

var layout: ZoneLayout
var nav: Nav
var world: Node2D
var fx_layer: Node2D
var player: Player
var spawner: Spawner
var camera: CameraRig
var ui: GameUi
var hud: Hud
var input: GameInput
var lamps: Array[Waylamp] = []
var cocoon: Cocoon
var flags: Dictionary = {}
var _dirty: bool = false
var _save_t: float = 0.0


func _ready() -> void:
	current = self
	GameData.ensure()
	InputSetup.ensure()
	FloatText.enabled = bool(GameData.setting("damage_numbers", true))
	layout = ZoneGen.make(GameData.biome, ZONE_SEED)
	nav = Nav.new(layout)
	Overlay.create(self)
	_build_world()
	ui = GameUi.new()
	add_child(ui)
	ui.setup(self)
	hud = ui.hud
	input = GameInput.new()
	add_child(input)
	input.setup(self)
	_story_start()
	if SaveGame.enabled() and SaveGame.read(self):
		hud.notice("Welcome back, Lamplighter")
	player.prog.changed.connect(mark_dirty)
	player.inv.changed.connect(mark_dirty)


func _exit_tree() -> void:
	if current == self:
		if SaveGame.enabled():
			SaveGame.write(self)
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
	var dark := CanvasModulate.new()
	var a: Array = GameData.biome["ambient"]["darkness"]
	dark.color = Color(float(a[0]), float(a[1]), float(a[2]))
	add_child(dark)
	player = Player.new()
	player.position = layout.start
	world.add_child(player)
	camera = CameraRig.new()
	add_child(camera)
	camera.setup(player, layout.size_px(), -ROOF_ROOM)
	Fx.motes(camera, MOTES_EXTENTS, MOTES, Pal.c("glint", 0.8))
	spawner = Spawner.new()
	add_child(spawner)
	spawner.setup(world, layout, player)
	spawner.boss_died.connect(_on_boss_died)
	_interactables()
	add_child(LabelStack.new())


func _interactables() -> void:
	var by_kind: Dictionary = {"chest": Chest, "waylamp": Waylamp, "npc": Npc, "cocoon": Cocoon, "note": LoreObject,
		"cairn": LoreObject, "statue_fisher": LoreObject, "signpost": LoreObject}
	for p: Dictionary in layout.props:
		if not by_kind.has(p["kind"]):
			continue
		var it: Interactable = (by_kind[p["kind"]] as GDScript).new().setup(p)
		world.add_child(it)
		if it is Waylamp:
			lamps.append(it)
			(it as Waylamp).lit_up.connect(func(_l: Waylamp) -> void: mark_dirty())
		elif it is Cocoon:
			cocoon = it


## 0 at the gate, 1 at the farthest point (drives enemy and loot level).
func progress_at(p: Vector2) -> float:
	return clampf(p.distance_to(layout.start) / layout.size_px().length() * 1.6, 0.0, 1.0)


func mark_dirty() -> void:
	_dirty = true


# ------------------------------------------------------------------ story beats
func _story_start() -> void:
	Audio.play_music("explore")
	var C: Dictionary = GameData.story["captions"]
	hud.caption(String(C["arrive"]))
	if SaveGame.enabled() and SaveGame.exists():
		return
	get_tree().create_timer(AMBUSH_DELAY, false).timeout.connect(func() -> void:
		spawner.opening_ambush()
		hud.caption(String(C["ambush"])))


func _process(delta: float) -> void:
	_beats()
	_save_t -= delta
	if _dirty and _save_t <= 0.0 and SaveGame.enabled():
		_save_t = SAVE_EVERY
		_dirty = false
		SaveGame.write(self)


func _beats() -> void:
	var C: Dictionary = GameData.story["captions"]
	if not flags.has("dark_tip") and player.light.value < DARK_TIP_LIGHT:
		flags["dark_tip"] = true
		hud.caption(String(C["first_dark"]))
	if not flags.has("level_tip") and player.prog.level >= 2:
		flags["level_tip"] = true
		hud.caption(String(C["first_level"]))
	if not flags.has("boss") and player.global_position.distance_to(layout.boss["pos"]) < BOSS_TRIGGER:
		start_boss()


func start_boss() -> void:
	flags["boss"] = true
	var b: Enemy = spawner.spawn_boss()
	b.wake()
	hud.track_boss(b)
	hud.caption(String(GameData.story["captions"]["boss"]))
	Audio.play_music("boss", 1.0)
	Audio.sfx("boss_wind", -2.0, 0.6)


func _on_boss_died(_e: Enemy) -> void:
	flags["boss_down"] = true
	Audio.play_music("explore", 3.0)
	if cocoon != null:
		cocoon.shatter(self)
		var nim := Npc.new()
		nim.setup({"kind": "npc", "npc": "nim", "pos": cocoon.global_position + Vector2(0, 24), "foot": Rect2()})
		world.add_child(nim)
		flags["nim_free"] = true
	mark_dirty()


func lit_lamps() -> int:
	return lamps.filter(func(l: Waylamp) -> bool: return l.lit).size()


## Guardian moths burn hostile shots that touch them.
func moth_guards_catch(at: Vector2) -> bool:
	for m: Node in get_tree().get_nodes_in_group("moth_guards"):
		if (m as Node2D).global_position.distance_to(at) < Moth.HIT_RADIUS * 2.0:
			Fx.halo(fx_layer, at, 16.0, Pal.c("flame", 0.8), 0.2)
			return true
	return false
