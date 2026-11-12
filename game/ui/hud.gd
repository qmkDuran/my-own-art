class_name Hud
extends CanvasLayer
## The minimal HUD: your life bar (bottom left), the four move icons (bottom centre), the stealth eye (bottom right),
## Thornback's life bar (top centre, only while you can see it or are locked on), the crosshair, the lock-on
## marker, the rustle cue, combat words and the start / pause / end screens.

const PLAYER_BAR_SIZE: Vector2 = Vector2(320, 44)
const BOT_BAR_SIZE: Vector2 = Vector2(420, 44)
const ICON_GAP: int = 14
const MOVES: Array[Array] = [["bite", "LMB", "Bite"], ["spit", "RMB", "Spit"], ["dodge", "SPACE", "Roll"],
	["trap", "F", "Snare"]]

var screens: Screens
var bot_bar: LifeBar
var stealth_eye: StealthEye
var _sight: PlayerSight
var _lock_on: LockOn


func setup(match_root: Main) -> void:
	name = "Hud"
	_sight = match_root.sight
	_lock_on = match_root.lock_on
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_add_overlays(root, match_root)
	_add_life_bars(root, match_root)
	_add_move_icons(root, match_root.player)
	stealth_eye = StealthEye.new()
	stealth_eye.setup(match_root.brain, match_root.player)
	var eye_size: Vector2 = StealthEye.PANEL_SIZE
	HudStyle.pin(stealth_eye, Vector2.ONE, -Vector2.ONE * HudStyle.MARGIN - eye_size, eye_size)
	root.add_child(stealth_eye)
	screens = Screens.new()
	root.add_child(screens)


func watch_flow(flow: MatchFlow) -> void:
	flow.phase_changed.connect(screens.show_phase)
	screens.show_phase(flow.phase)


func _process(_delta: float) -> void:
	bot_bar.visible = _sight.sees_bot or _lock_on.target_locked()


func _add_overlays(root: Control, match_root: Main) -> void:
	var crosshair := Crosshair.new()
	crosshair.setup(match_root.lock_on)
	root.add_child(crosshair)
	var marker := LockMarker.new()
	marker.setup(match_root.lock_on, match_root.rig.camera)
	root.add_child(marker)
	var rustle := RustleCue.new()
	rustle.setup(match_root.sight, match_root.rig)
	root.add_child(rustle)
	var words := CombatText.new()
	words.setup(match_root.player, match_root.bot)
	root.add_child(words)


func _add_life_bars(root: Control, match_root: Main) -> void:
	var player_bar := LifeBar.new()
	player_bar.setup(match_root.player.health, match_root.player.display_name, HudStyle.LIFE_PLAYER, PLAYER_BAR_SIZE)
	var bar_at := Vector2(HudStyle.MARGIN, -HudStyle.MARGIN - PLAYER_BAR_SIZE.y)
	HudStyle.pin(player_bar, Vector2(0, 1), bar_at, PLAYER_BAR_SIZE)
	root.add_child(player_bar)
	bot_bar = LifeBar.new()
	bot_bar.setup(match_root.bot.health, match_root.bot.display_name, HudStyle.LIFE_BOT, BOT_BAR_SIZE)
	HudStyle.pin(bot_bar, Vector2(0.5, 0), Vector2(-BOT_BAR_SIZE.x * 0.5, HudStyle.MARGIN), BOT_BAR_SIZE)
	root.add_child(bot_bar)


func _add_move_icons(root: Control, player: Creature) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", ICON_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for move: Array in MOVES:
		var icon := AbilityIcon.new()
		icon.setup(player.get(move[0]), move[1], move[2], _tint(move[0]))
		row.add_child(icon)
	root.add_child(row)
	var row_size: Vector2 = row.get_combined_minimum_size()
	HudStyle.pin(row, Vector2(0.5, 1), Vector2(-row_size.x * 0.5, -HudStyle.MARGIN - row_size.y), row_size)


static func _tint(move: String) -> Color:
	var glow: Dictionary = Tuning.creatures["glow"]
	return Tuning.color(glow[move]) if glow.has(move) else HudStyle.INK
