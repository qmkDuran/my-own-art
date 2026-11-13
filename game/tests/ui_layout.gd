class_name UiLayout
extends RefCounted
## UI layout checks for the smoke test: the town HUD, the night HUD (with a full ingredient bag and the Gloom
## King's bar) and the level-up panel are laid out at each logical screen size the game can have (the project
## stretches the UI from 1280x720, so 16:9 screens from 1280x720 to 2560x1440 all look like 1280x720, 16:10 like
## 1280x800 and 21:9 like about 1707x720). Every visible part must sit on screen, HUD parts must not overlap, and
## card text must stay inside its card.

const SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(1707, 720)]
const SLACK: float = 1.0

var m: Main
var failures: Array[String] = []


func _init(main: Main) -> void:
	m = main


func run() -> Array[String]:
	m.start_night()
	m.night.set_physics_process(false)
	m.night.bag = { "pumpkin_goo": 12, "moth_dust": 9, "ghost_pepper": 7, "moonberry": 10, "batwing_toffee": 3 }
	m.night.horde.spawn("gloom_king", m.player.global_position + Vector3(10, 0, 0)).set_physics_process(false)
	m.hud.show_hints()
	for size: Vector2i in SIZES:
		await _check_size(size)
	m.night.finish(true)
	return failures


func _check_size(size: Vector2i) -> void:
	var holder := SubViewport.new()
	holder.size = size
	m.add_child(holder)
	var layers: Array[CanvasLayer] = [m.hud, m.night_hud, m.level_panel]
	for layer: CanvasLayer in layers:
		layer.reparent(holder)
	m.level_panel.show_offers(m.night.loadout.offers())
	for frame: int in 3:
		await m.get_tree().process_frame
	var screen := Rect2(Vector2.ZERO, Vector2(size)).grow(SLACK)
	for layer: CanvasLayer in layers:
		for node: Node in layer.find_children("*", "Control", true, false):
			var control: Control = node
			if control.is_visible_in_tree() and not screen.encloses(control.get_global_rect()):
				failures.append("ui %s: %s %s is off screen" % [size, control.name, control.get_global_rect()])
	_check_hud_overlaps(size)
	_check_cards(size)
	m.level_panel.pick(0)
	for layer: CanvasLayer in layers:
		layer.reparent(m)
	holder.queue_free()


func _check_hud_overlaps(size: Vector2i) -> void:
	var parts: Array[Control] = [m.hud.hint_label()]
	for node: Node in m.night_hud.root.get_children():
		parts.append(node as Control)
	var shown: Array[Control] = parts.filter(_is_shown)
	for i: int in shown.size():
		for j: int in range(i + 1, shown.size()):
			if shown[i].get_global_rect().intersects(shown[j].get_global_rect()):
				failures.append("ui %s: %s overlaps %s" % [size, shown[i].name, shown[j].name])


func _check_cards(size: Vector2i) -> void:
	for card: Button in m.level_panel.cards:
		var bounds: Rect2 = card.get_global_rect().grow(SLACK)
		for node: Node in card.find_children("*", "Label", true, false):
			var label: Label = node
			if not bounds.encloses(label.get_global_rect()):
				failures.append("ui %s: card text '%s' spills out of its card" % [size, label.text])


static func _is_shown(control: Control) -> bool:
	return control.is_visible_in_tree() and control.modulate.a > 0.0
