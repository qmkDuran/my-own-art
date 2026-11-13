class_name StatusView
extends Control
## The player's active effects as short words above the life bar (Faster, Stronger, Slowed, Blinded, Confused,
## Hearing, Exposed ...), and a dark veil over the screen while blinded by dirt.

const NAMES: Dictionary = { "speed": "Faster", "slow": "Slowed", "damage_out": "Power", "damage_in": "Tough",
	"shield": "Ward", "blind": "Blinded", "confused": "Confused", "crit": "Steady eye", "hearing": "Keen ears",
	"glide": "Gliding", "rooted": "Rooted" }
const LINE_Y: float = -96.0
const VEIL: Color = Color(0.02, 0.02, 0.02, 0.72)
const WEAK_COLOR: Color = Color(1.0, 0.55, 0.45)
const WEAK_EFFECTS: Array[String] = ["slow", "blind", "confused", "rooted"]
const WORD_GAP: String = "   "

var _player: Creature


func setup(player: Creature) -> void:
	_player = player
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _player.effects.has("blind"):
		draw_rect(Rect2(Vector2.ZERO, size), VEIL)
	var at := Vector2(HudStyle.MARGIN, size.y + LINE_Y)
	for effect: String in _player.effects.names():
		if not NAMES.has(effect):
			continue
		var word: String = "%s %.0fs" % [NAMES[effect], ceilf(_player.effects.time_left(effect))]
		var color: Color = WEAK_COLOR if WEAK_EFFECTS.has(effect) else HudStyle.AMBUSH_COLOR
		HudStyle.text(self, at, word, HudStyle.FONT_SMALL, color, HORIZONTAL_ALIGNMENT_LEFT, -1)
		at.x += ThemeDB.fallback_font.get_string_size(word + WORD_GAP, HORIZONTAL_ALIGNMENT_LEFT, -1,
				HudStyle.FONT_SMALL).x
	if _player.stealth.is_exposed():
		HudStyle.text(self, at, "Exposed", HudStyle.FONT_SMALL, WEAK_COLOR, HORIZONTAL_ALIGNMENT_LEFT, -1)
