class_name Game
extends Node
## The in-game scene: hosts the current Zone and the player plus HUD, dialogue box,
## inventory and vignette. Router drives transitions; Game builds what it is told to.

const VIGNETTE_SHADER := preload("res://shaders/vignette.gdshader")

var zone: Zone
var player: Player
var hud: Hud
var dialogue_box: DialogueBox
var inventory_panel: InventoryPanel

var _zone_host: Node2D
var _vignette: ColorRect
var _vignette_material: ShaderMaterial


func _ready() -> void:
	_zone_host = Node2D.new()
	_zone_host.name = "ZoneHost"
	add_child(_zone_host)
	_add_vignette()
	hud = Hud.new()
	add_child(hud)
	inventory_panel = InventoryPanel.new()
	add_child(inventory_panel)
	dialogue_box = DialogueBox.new()
	add_child(dialogue_box)
	Dialogue.register_box(dialogue_box)
	Router.register_game(self)


func _exit_tree() -> void:
	if Dialogue.box == dialogue_box:
		Dialogue.register_box(null)
	if Router.game == self:
		Router.game = null


## Replaces the current zone. spawn_position (Vector2) wins over spawn_id when given.
func load_zone(zone_id: String, spawn_id: String, spawn_position: Variant) -> void:
	if zone:
		_zone_host.remove_child(zone)
		zone.queue_free()
	HitStop.reset()
	zone = Zone.new()
	zone.build(zone_id)
	_zone_host.add_child(zone)
	player = Player.new()
	player.name = "Player"
	player.position = spawn_position if spawn_position is Vector2 else zone.spawn_position(spawn_id)
	zone.entities_root.add_child(player)
	player.camera.set_bounds(_camera_bounds(zone.bounds()))
	player.camera.reset_smoothing()
	set_vignette(float(zone.setting("vignette", 0.45)), 0.0)
	zone.start_audio()
	Events.interact_prompt_changed.emit("")
	Events.zone_entered.emit(zone_id)


## Runs the zone's "on_enter" scripts whose conditions hold (once each by default).
func run_zone_entry_scripts() -> void:
	for entry: Variant in zone.entry_scripts():
		var script: Dictionary = entry
		var done_flag := "done:" + String(script.get("id", script.get("run", "")))
		if script.get("once", true) and GameState.flags.is_set(done_flag):
			continue
		if not Condition.check(script.get("if")):
			continue
		GameState.flags.set_flag(done_flag)
		await Dialogue.run(String(script.get("run", "")))


func set_vignette(strength: float, duration: float) -> void:
	if duration <= 0.0:
		_vignette_material.set_shader_parameter("strength", strength)
		return
	var from: float = _vignette_material.get_shader_parameter("strength")
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: _vignette_material.set_shader_parameter("strength", v), from, strength, duration)


func _add_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Vignette"
	layer.layer = 5
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_material = ShaderMaterial.new()
	_vignette_material.shader = VIGNETTE_SHADER
	_vignette_material.set_shader_parameter("strength", 0.45)
	_vignette.material = _vignette_material
	layer.add_child(_vignette)
	add_child(layer)


## Centres zones smaller than the screen instead of pinning them to the top-left.
func _camera_bounds(bounds: Rect2) -> Rect2:
	var view := get_viewport().get_visible_rect().size
	var result := bounds
	if bounds.size.x < view.x:
		result.position.x -= (view.x - bounds.size.x) / 2.0
		result.size.x = view.x
	if bounds.size.y < view.y:
		result.position.y -= (view.y - bounds.size.y) / 2.0
		result.size.y = view.y
	return result
