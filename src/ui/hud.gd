class_name Hud
extends CanvasLayer
## Health, equipped weapon, the interaction prompt and short toast messages.

const TOAST_TIME := 2.2

var _health_bar: ProgressBar
var _weapon_label: Label
var _prompt: Label
var _toast: Label
var _toast_tween: Tween


func _ready() -> void:
	layer = 10
	var top := HBoxContainer.new()
	top.position = Vector2(16, 12)
	top.add_theme_constant_override("separation", 10)
	top.add_child(UiStyle.label("HP", 14, UiStyle.DIM))
	_health_bar = _make_health_bar()
	top.add_child(_health_bar)
	_weapon_label = UiStyle.label("", 14, UiStyle.DIM)
	top.add_child(_weapon_label)
	add_child(top)
	_prompt = UiStyle.label("", 16, UiStyle.ACCENT)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.position = Vector2(0, 340)
	_prompt.size = Vector2(960, 24)
	add_child(_prompt)
	_toast = UiStyle.label("", 16)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(0, 48)
	_toast.size = Vector2(960, 24)
	_toast.modulate.a = 0.0
	add_child(_toast)
	Events.player_health_changed.connect(_on_health_changed)
	Events.interact_prompt_changed.connect(_on_prompt_changed)
	Events.toast.connect(show_toast)
	GameState.inventory.changed.connect(_update_weapon)
	_on_health_changed(GameState.hp, GameState.max_hp)
	_update_weapon()


func _process(_delta: float) -> void:
	_prompt.visible = not Router.is_gameplay_paused()


func show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(TOAST_TIME)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)


func _on_health_changed(hp: int, max_hp: int) -> void:
	_health_bar.max_value = max_hp
	_health_bar.value = hp


func _on_prompt_changed(text: String) -> void:
	_prompt.text = "" if text.is_empty() else "[E]  %s" % text


func _update_weapon() -> void:
	var weapon := GameState.inventory.equipped_weapon
	_weapon_label.text = "" if weapon.is_empty() else "Holding: %s" % String(DB.item(weapon).get("name", weapon))


func _make_health_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(140, 12)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("c04a3a")
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0, 0, 0, 0.6)
	back.border_color = UiStyle.BORDER
	back.set_border_width_all(1)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	return bar
