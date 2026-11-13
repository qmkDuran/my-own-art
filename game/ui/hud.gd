class_name Hud
extends CanvasLayer
## The minimal HUD: your life bar with active effects (bottom left), your four equipped moves and the roll (bottom
## centre), the stealth eye (bottom right), Thornback's life bar (top centre, only while you can see it or are
## locked on), the crosshair, the lock-on marker, a dim veil while blinded, combat words and the loadout / pause /
## end screens.

const PLAYER_BAR_SIZE: Vector2 = Vector2(320, 44)
const BOT_BAR_SIZE: Vector2 = Vector2(420, 44)
const ICON_GAP: int = 14
const KEYS: Array[String] = ["LMB", "RMB", "Q", "E"]
const ROLL_KEY: String = "SPACE"
const ROLL_TITLE: String = "Roll"

var screens: Screens
var bot_bar: LifeBar
var stealth_eye: StealthEye
var _sight: PlayerSight
var _lock_on: LockOn
var _root: Control
var _move_row: HBoxContainer


func setup(match_root: Main) -> void:
	name = "Hud"
	_sight = match_root.sight
	_lock_on = match_root.lock_on
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_root = root
	_add_overlays(root, match_root)
	_add_life_bars(root, match_root)
	show_moves(match_root.player)
	stealth_eye = StealthEye.new()
	stealth_eye.setup(match_root.brain, match_root.player)
	var eye_size: Vector2 = StealthEye.PANEL_SIZE
	HudStyle.pin(stealth_eye, Vector2.ONE, -Vector2.ONE * HudStyle.MARGIN - eye_size, eye_size)
	root.add_child(stealth_eye)
	screens = Screens.new()
	screens.main = match_root
	root.add_child(screens)


## The F3 view sits under the start / pause screens.
func add_overlay(overlay: Control) -> void:
	HudStyle.pin(overlay, Vector2.ZERO, Vector2.ONE * HudStyle.MARGIN, DebugOverlay.PANEL_SIZE)
	screens.get_parent().add_child(overlay)
	screens.get_parent().move_child(overlay, screens.get_index())


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
	var veil := StatusView.new()
	veil.setup(match_root.player)
	root.add_child(veil)
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


## (Re)builds the move icons from the creature's current loadout.
func show_moves(player: Creature) -> void:
	if is_instance_valid(_move_row):
		_move_row.queue_free()
	_move_row = HBoxContainer.new()
	_move_row.add_theme_constant_override("separation", ICON_GAP)
	_move_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for slot: int in player.moves.size():
		var move: Move = player.moves[slot]
		var icon := AbilityIcon.new()
		icon.setup(move, KEYS[slot], move.display_name(), _tint(move.spec["glow"]), IconGlyphs.for_move(move))
		_move_row.add_child(icon)
	var roll_icon := AbilityIcon.new()
	roll_icon.setup(player.roll, ROLL_KEY, ROLL_TITLE, HudStyle.INK, IconGlyphs.roll)
	_move_row.add_child(roll_icon)
	_root.add_child(_move_row)
	if is_instance_valid(screens):
		_root.move_child(_move_row, screens.get_index())
	var row_size: Vector2 = _move_row.get_combined_minimum_size()
	HudStyle.pin(_move_row, Vector2(0.5, 1), Vector2(-row_size.x * 0.5, -HudStyle.MARGIN - row_size.y), row_size)


static func _tint(glow_key: String) -> Color:
	var glow: Dictionary = Tuning.creatures["glow"]
	return Tuning.color(glow[glow_key]) if glow.has(glow_key) else HudStyle.INK
