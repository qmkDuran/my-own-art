class_name CombatHud
extends CanvasLayer
## The combat HUD, kept clean: the crosshair in the centre; health and the mission objective top left; the boss's
## bar top centre (with his phase); the abilities bottom right (cooldown sweeps, the heavy's charge, the super's
## meter glowing when full); big banners for the mission's moments; and a soft fade for travelling home.

const SLOTS: Array = [["primary", "LMB"], ["heavy", "RMB"], ["bomb", "Q"], ["ward", "E"], ["blink", "V"],
	["super", "R"]]
const BANNER_TOP: float = 0.22
const BANNER_SIDE: float = 0.22
const FADE_COLOUR: Color = Color(0.02, 0.02, 0.05, 1.0)
const PERCENT: float = 100.0

var root: Control
var crosshair: Crosshair
var slots: Dictionary = {}
var health_bar: ProgressBar
var boss_box: VBoxContainer
var boss_bar: ProgressBar
var boss_label: Label
var objective: Label
var banner_label: Label
var fade: ColorRect
var _kit: LamplighterKit
var _banner_left: float = 0.0


func setup(kit: LamplighterKit, mission: Mission) -> void:
	name = "CombatHud"
	_kit = kit
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	crosshair = Crosshair.new()
	crosshair.set_anchors_preset(Control.PRESET_FULL_RECT)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(crosshair)
	_top_left()
	_boss()
	_abilities()
	_banner()
	kit.hit_landed.connect(func(_critical: bool, killed: bool) -> void: crosshair.flash_hit(killed))
	kit.health.changed.connect(func(health: float, most: float) -> void: health_bar.value = health / most * PERCENT)
	mission.banner.connect(banner)
	mission.objective_changed.connect(func(text: String) -> void: objective.text = text)
	mission.travelling.connect(travel_fade)


func _top_left() -> void:
	var box := VBoxContainer.new()
	box.name = "Status"
	var margin: int = Tuning.i("combat_hud", "margin")
	box.position = Vector2(margin, margin)
	root.add_child(box)
	health_bar = UiStyle.bar(AbilitySlot.colour_of("health"), Tuning.i("combat_hud", "bar_height"))
	health_bar.custom_minimum_size.x = Tuning.f("combat_hud", "bar_width")
	health_bar.value = PERCENT
	box.add_child(health_bar)
	objective = UiStyle.label("", Tuning.i("combat_hud", "objective_font"))
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size.x = Tuning.f("combat_hud", "bar_width")
	box.add_child(objective)


func _boss() -> void:
	boss_box = VBoxContainer.new()
	boss_box.name = "Boss"
	boss_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE,
		Tuning.i("combat_hud", "margin"))
	boss_box.custom_minimum_size.x = Tuning.f("combat_hud", "boss_width")
	boss_box.position.x -= Tuning.f("combat_hud", "boss_width") * 0.5
	root.add_child(boss_box)
	boss_label = UiStyle.label("The Gloom King", Tuning.i("combat_hud", "boss_font"))
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(boss_label)
	boss_bar = UiStyle.bar(AbilitySlot.colour_of("boss"), Tuning.i("combat_hud", "bar_height"))
	boss_box.add_child(boss_bar)
	boss_box.visible = false


func _abilities() -> void:
	var row := HBoxContainer.new()
	row.name = "Abilities"
	row.add_theme_constant_override("separation", Tuning.i("combat_hud", "slot_gap"))
	for pair: Array in SLOTS:
		var slot := AbilitySlot.new()
		slot.setup(pair[0], pair[1])
		row.add_child(slot)
		slots[pair[0]] = slot
	root.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE,
		Tuning.i("combat_hud", "margin"))
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _banner() -> void:
	banner_label = UiStyle.label("", Tuning.i("combat_hud", "banner_font"))
	banner_label.name = "Banner"
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.anchor_left = BANNER_SIDE
	banner_label.anchor_right = 1.0 - BANNER_SIDE
	banner_label.anchor_top = BANNER_TOP
	banner_label.anchor_bottom = BANNER_TOP
	root.add_child(banner_label)
	fade = ColorRect.new()
	fade.color = FADE_COLOUR
	fade.modulate.a = 0.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)


func banner(text: String, seconds: float) -> void:
	banner_label.text = text
	_banner_left = seconds


## Fades to dark over a time, then back.
func travel_fade(seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, seconds)
	tween.tween_property(fade, "modulate:a", 0.0, seconds)


func _process(delta: float) -> void:
	_banner_left = maxf(_banner_left - delta, 0.0)
	banner_label.modulate.a = clampf(_banner_left, 0.0, 1.0)
	for ability: String in _kit.cooldowns:
		(slots[ability] as AbilitySlot).cooldown = (_kit.cooldowns[ability] as Cooldown).share()
	var heavy: AbilitySlot = slots["heavy"]
	heavy.fill = _kit.heavy.share() if _kit.heavy.charging else -1.0
	crosshair.charge = _kit.heavy.share() if _kit.heavy.charging else 0.0
	var sun: AbilitySlot = slots["super"]
	sun.fill = _kit.meter.share()
	sun.full = _kit.meter.is_full()
	_boss_bar()
	_lock_marker()


func _boss_bar() -> void:
	var boss: Enemy = _kit.roster.boss()
	boss_box.visible = boss != null
	if boss == null:
		return
	boss_bar.value = boss.health / boss.max_health * PERCENT
	var phase: int = (boss.brain as BossBrain).phase
	boss_label.text = "The Gloom King" + ("  -  enraged" if phase == 2 else "")


func _lock_marker() -> void:
	var target: Enemy = _kit.aim.target
	var camera: Camera3D = _kit.camera_rig.camera
	if target == null or not is_instance_valid(target) or camera.is_position_behind(target.centre()):
		crosshair.lock_at = Vector2.INF
		return
	crosshair.lock_at = camera.unproject_position(target.centre())
