class_name DefenceHud
extends CanvasLayer
## The night's HUD: an experience bar and level across the top, the time left, health, lamps still lit, the
## ingredient bag, the Gloom King's health when he comes, and big centre banners for the start and end of a night.

const XP_COLOUR: Color = Color(0.55, 0.9, 1.0)
const HEALTH_COLOUR: Color = Color(1.0, 0.45, 0.4)
const BOSS_COLOUR: Color = Color(0.65, 0.4, 1.0)
const BAR_HEIGHT: int = 14
const BIG: int = 40
const SMALL: int = 18
const SIDE_WIDTH: int = 260
const BOSS_WIDTH_SHARE: float = 0.4
const PERCENT: float = 100.0

var root: Control
var _run: NightRun
var _xp: ProgressBar
var _health: ProgressBar
var _boss: ProgressBar
var _clock: Label
var _status: Label
var _banner: Label
var _banner_timer: float = 0.0


func setup(run: NightRun) -> void:
	name = "DefenceHud"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run = run
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_xp = UiStyle.bar(XP_COLOUR, BAR_HEIGHT)
	_place(_xp, Control.PRESET_TOP_WIDE)
	_clock = UiStyle.label("", BIG)
	_place(_clock, Control.PRESET_CENTER_TOP)
	_clock.position.y = BAR_HEIGHT + UiStyle.PADDING * 2
	_health = UiStyle.bar(HEALTH_COLOUR, BAR_HEIGHT)
	_health.custom_minimum_size.x = SIDE_WIDTH
	_place(_health, Control.PRESET_BOTTOM_LEFT)
	_status = UiStyle.label("", SMALL)
	_place(_status, Control.PRESET_TOP_LEFT)
	_status.position = Vector2(UiStyle.PADDING, BAR_HEIGHT + UiStyle.PADDING * 2)
	_boss = UiStyle.bar(BOSS_COLOUR, BAR_HEIGHT)
	_place(_boss, Control.PRESET_CENTER_BOTTOM)
	_banner = UiStyle.label("", BIG)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_banner)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	visible = false


func banner(text: String, seconds: float) -> void:
	_banner.text = text
	_banner_timer = seconds
	_banner.reset_size()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func _place(control: Control, preset: Control.LayoutPreset) -> void:
	root.add_child(control)
	control.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, UiStyle.PADDING)


func _process(delta: float) -> void:
	_banner_timer = maxf(_banner_timer - delta, 0.0)
	_banner.modulate.a = clampf(_banner_timer, 0.0, 1.0)
	_banner.visible = _banner_timer > 0.0
	var running: bool = _run.state == NightRun.State.RUNNING
	for part: Control in [_xp, _clock, _health, _status]:
		part.visible = running
	_boss.visible = running and _run.horde.boss() != null
	if not running:
		return
	_xp.value = _run.xp / _run.xp_needed() * PERCENT
	var left: int = int(maxf(_run.length - _run.clock, 0.0))
	_clock.text = "%d:%02d" % [left / 60, left % 60]
	_health.value = _run.vitality.health / _run.vitality.max_health * PERCENT
	_status.text = "Level %d    Lamps lit %d/%d\n%s" % [_run.level, _run.lamps.lit_count(), _run.lamps.lamps.size(),
		bag_text(_run.bag)]
	if _boss.visible:
		var king: Creature = _run.horde.boss()
		_boss.custom_minimum_size.x = root.size.x * BOSS_WIDTH_SHARE
		_boss.value = king.health / float(king.spec["health"]) / _run.horde.toughness * PERCENT


static func bag_text(bag: Dictionary) -> String:
	var lines: PackedStringArray = []
	for item: String in bag:
		lines.append("%s x%d" % [Tuning.doc("defence")["ingredients"][item]["name"], int(bag[item])])
	return "\n".join(lines)
