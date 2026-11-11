class_name DevMenu
extends CanvasLayer
## F1: the playtest menu. Jump to any zone, its next waylamp or its boss arena; set the level (points and a matching
## gear preset come with it); god mode and one-hit kills; spawn a pack; time scale; restart the boss fight; draw
## hitboxes and light radii. Plain Godot buttons: it is a tool, not part of the game's look.

const LAYER: int = 49
const LEVELS: Array[int] = [5, 10, 15, 20, 25, 30]
const SPEEDS: Array[float] = [0.5, 1.0, 2.0, 4.0]
const SPAWN_AHEAD := Vector2(160, 0)
const PACK_SIZE: int = 4

var g: Game
var _panel: PanelContainer
var _box: VBoxContainer
var _kind: int = 0


func setup(game: Game) -> void:
	g = game
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.position = Vector2(12, 12)
	_panel.visible = false
	add_child(_panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 500)
	_panel.add_child(scroll)
	_box = VBoxContainer.new()
	scroll.add_child(_box)
	_build()


func toggle() -> void:
	_panel.visible = not _panel.visible


func is_open() -> bool:
	return _panel.visible


func _build() -> void:
	_title("Travel")
	_row(GameData.zones["zones"].keys(), func(z: String) -> void: Session.travel(g, z))
	_button("Next unlit waylamp", _to_lamp)
	_button("Boss arena", func() -> void: _place(g.layout.circle_center() + Vector2(0, 140)))
	_title("Character")
	_row(LEVELS.map(func(l: int) -> String: return "Lv %d" % l), func(t: String) -> void: _set_level(int(t.substr(3))))
	_button("God mode", func() -> void: Dev.god = not Dev.god, true)
	_button("One-hit kills", func() -> void: Dev.one_hit = not Dev.one_hit, true)
	_title("Enemies")
	_button("Spawn a pack", _spawn)
	_button("Next enemy kind", func() -> void: _kind = (_kind + 1) % GameData.enemies["kinds"].size(); g.hud.notice("Spawn: " + _kind_name()))
	_button("Restart the boss fight", _restart_boss)
	_title("Time and view")
	_row(SPEEDS.map(func(s: float) -> String: return "x%s" % s), func(t: String) -> void: Engine.time_scale = float(t.substr(1)))
	_button("Hitboxes", func() -> void: Dev.show_boxes = not Dev.show_boxes, true)
	_button("Light radii", func() -> void: Dev.show_light = not Dev.show_light, true)


func _title(text: String) -> void:
	var l := Label.new()
	l.text = text
	_box.add_child(l)


func _button(text: String, fn: Callable, toggle_btn: bool = false) -> void:
	var b := Button.new()
	b.text = text
	b.toggle_mode = toggle_btn
	b.pressed.connect(fn)
	_box.add_child(b)


func _row(labels: Array, fn: Callable) -> void:
	var flow := HFlowContainer.new()
	for t: Variant in labels:
		var b := Button.new()
		b.text = String(t)
		b.pressed.connect(func() -> void: fn.call(String(t)))
		flow.add_child(b)
	_box.add_child(flow)


func _place(at: Vector2) -> void:
	g.player.global_position = g.layout.free_spot_near(at, g.player.radius)
	g.camera.reset_smoothing()


func _to_lamp() -> void:
	for l: Waylamp in g.lamps:
		if not l.lit:
			_place(l.stand_point())
			return


func _set_level(level: int) -> void:
	ShotHelper.new(g).player_build(level)
	g.hud.notice("Level %d, points spent, rare gear of that level" % level)


func _kind_name() -> String:
	return String(GameData.enemies["kinds"].keys()[_kind])


func _spawn() -> void:
	var kinds: Array = []
	for k: int in PACK_SIZE:
		kinds.append(_kind_name())
	ShotHelper.new(g).pack_near(kinds, SPAWN_AHEAD)


func _restart_boss() -> void:
	var b: Enemy = g.spawner.boss
	if b != null and is_instance_valid(b) and not b.dead:
		b.life = b.max_life
		b.global_position = b.home
	g.player.life = g.player.stats.max_life()
	g.player.refill_tonics()
	_place(g.layout.circle_center() + Vector2(0, 140))
