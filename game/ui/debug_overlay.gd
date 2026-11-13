class_name DebugOverlay
extends Control
## F3: what the bot is thinking. Its current action and the utility scores behind it, the difficulty, what it has
## learned about you (and a "learning" flash when it just learned something), and its latest barks such as "It
## remembers you like the tall grass". Off by default; the game is meant to be read without it.

const PANEL_SIZE: Vector2 = Vector2(390, 420)
const LINE: float = 19.0
const PAD: float = 12.0
const SCORES_SHOWN: int = 6
const PERCENT: float = 100.0
const LEARNING_COLOR: Color = Color(0.55, 0.85, 1.0)

var _brain: BotBrain
var _markers: TacticalMarkers


func setup(brain: BotBrain, markers: TacticalMarkers) -> void:
	_brain = brain
	_markers = markers
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func toggle() -> void:
	visible = not visible
	_markers.visible = visible


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var lines: Array[Array] = _lines()
	HudStyle.panel(self, Rect2(Vector2.ZERO, Vector2(PANEL_SIZE.x, PAD * 2.0 + LINE * (lines.size() + 0.5))))
	for k: int in lines.size():
		HudStyle.text(self, Vector2(PAD, PAD + LINE * (k + 1)), lines[k][0], HudStyle.FONT_SMALL, lines[k][1],
				HORIZONTAL_ALIGNMENT_LEFT, PANEL_SIZE.x - PAD * 2.0)


func _lines() -> Array[Array]:
	var lines: Array[Array] = [["BOT MIND (F3)   difficulty: %s" % Difficulty.level, HudStyle.INK],
		["doing: %s" % _brain.state_name, HudStyle.AMBUSH_COLOR]]
	var scores: Dictionary = _brain.selector.last_scores
	var ranked: Array = scores.keys()
	ranked.sort_custom(func(a: String, b: String) -> bool: return scores[a] > scores[b])
	for option: String in ranked.slice(0, SCORES_SHOWN):
		lines.append(["  %-8s %.2f" % [option, float(scores[option])], HudStyle.INK_DIM])
	var model: PlayerModel = _brain.model
	lines.append(["memory: %d fights · hides in: %s" % [int(model.data["fights"]),
		model.favourite_kind() if model.favourite_kind() != "" else "?"], HudStyle.INK])
	lines.append(["  early rolls %d%% · melee %d%% · ranged %d%%" % [roundi(model.early_roll_share() * PERCENT),
		roundi(model.role_share("melee") * PERCENT), roundi(model.role_share("ranged") * PERCENT)], HudStyle.INK])
	if _brain.learning_left > 0.0:
		lines.append(["the bot is learning", LEARNING_COLOR])
	for words: String in _brain.barks:
		lines.append(["> " + words, LEARNING_COLOR])
	return lines
