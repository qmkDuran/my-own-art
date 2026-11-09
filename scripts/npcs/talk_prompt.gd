class_name TalkPrompt
extends Node2D
## The little "F TALK" tag over a townsperson's head while Emberoo is close enough to talk
## (Npc shows and hides it). Drawn in the HUD's tiny pixel font, the key read from the
## InputMap, bobbing gently. The node's origin is the tag's bottom-centre.

## Pixels the tag bobs up and down, and seconds per bob.
const BOB_PIXELS := 1.0
const BOB_SECONDS := 1.2

var _elapsed: float = 0.0
var _text: String = ""


func _ready() -> void:
	visible = false
	z_index = 2
	var key := InputKeyLabel.for_action("trainer_aid")
	_text = ("%s TALK" % key) if key != "" else "TALK"


func _process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	var width := PixelFont.width_of(_text)
	var bob := roundf(sin(_elapsed * TAU / BOB_SECONDS) * BOB_PIXELS)
	var top_left := Vector2(-roundf(width / 2.0), -PixelFont.GLYPH_HEIGHT + bob)
	draw_rect(Rect2(top_left - Vector2(2, 2), Vector2(width + 4, PixelFont.GLYPH_HEIGHT + 4)), Color(ApolloPalette.OUTLINE, 0.6))
	PixelFont.draw_text(self, _text, top_left, ApolloPalette.CREAM, ApolloPalette.OUTLINE)
