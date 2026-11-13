class_name UiLayout
extends RefCounted
## UI layout checks for the smoke test: the town HUD (hints), the combat HUD (health and objective, the Gloom
## King's bar, the abilities, a banner) and the performance overlay are laid out at each logical screen size the
## game can have (the project stretches the UI from 1280x720, so 16:9 screens from 1280x720 to 2560x1440 all look
## like 1280x720, 16:10 like 1280x800 and 21:9 like about 1707x720). Every visible part must sit on screen and HUD
## parts must not overlap.

const SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(1707, 720)]
const SLACK: float = 1.0

var m: Main
var failures: Array[String] = []


func _init(main: Main) -> void:
	m = main


func run() -> Array[String]:
	var boss: Enemy = m.roster.spawn("gloom_king", m.player.global_position + Vector3(10, 0, 0))
	boss.set_physics_process(false)
	m.combat_hud.objective.text = Tuning.doc("mission")["objective"]
	m.combat_hud.banner("Mission complete!\nThe Gloomwood glows again.", 1.0)
	m.hud.show_hints()
	m.perf_overlay.toggle()
	for size: Vector2i in SIZES:
		await _check_size(size)
	m.perf_overlay.toggle()
	m.roster.clear()
	return failures


func _check_size(size: Vector2i) -> void:
	var holder := SubViewport.new()
	holder.size = size
	m.add_child(holder)
	var layers: Array[CanvasLayer] = [m.hud, m.combat_hud, m.perf_overlay]
	for layer: CanvasLayer in layers:
		layer.reparent(holder)
	for frame: int in 3:
		await m.get_tree().process_frame
	var screen := Rect2(Vector2.ZERO, Vector2(size)).grow(SLACK)
	for layer: CanvasLayer in layers:
		for node: Node in layer.find_children("*", "Control", true, false):
			var control: Control = node
			if control.is_visible_in_tree() and not screen.encloses(control.get_global_rect()):
				failures.append("ui %s: %s %s is off screen" % [size, control.name, control.get_global_rect()])
	_check_hud_overlaps(size)
	for layer: CanvasLayer in layers:
		layer.reparent(m)
	holder.queue_free()


func _check_hud_overlaps(size: Vector2i) -> void:
	var parts: Array[Control] = [m.hud.hint_label(), m.perf_overlay.get_child(0) as Control]
	for node: Node in m.combat_hud.root.get_children():
		parts.append(node as Control)
	var shown: Array[Control] = parts.filter(_is_shown)
	for i: int in shown.size():
		for j: int in range(i + 1, shown.size()):
			if shown[i].get_global_rect().intersects(shown[j].get_global_rect()):
				failures.append("ui %s: %s overlaps %s" % [size, shown[i].name, shown[j].name])


static func _is_shown(control: Control) -> bool:
	return control.is_visible_in_tree() and control.modulate.a > 0.0
