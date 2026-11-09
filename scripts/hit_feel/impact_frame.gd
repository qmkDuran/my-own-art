class_name ImpactFrame
extends CanvasLayer
## The impact frame on a reaction finisher: for one real frame the screen dips under a light
## dark wash, then one frame of a faint pale flash, then it's gone. Counted in rendered
## frames, so a hit-stop doesn't stretch it. Kept light (the fight stays readable) and never
## stacked: one asked for within a few frames of the last is skipped.

const DARK_FRAMES := 1
const LIGHT_FRAMES := 1
const DARK_ALPHA := 0.25
const LIGHT_ALPHA := 0.12
## An impact frame asked for this few rendered frames after the last one is skipped.
const MIN_GAP_FRAMES := 12

static var _last_play_frame: int = -MIN_GAP_FRAMES

var _cover := ColorRect.new()
var _frames_shown: int = 0


static func play(asker: Node) -> void:
	var now := Engine.get_process_frames()
	if now - _last_play_frame < MIN_GAP_FRAMES:
		return
	_last_play_frame = now
	var frame := ImpactFrame.new()
	frame.layer = 40
	frame.process_mode = Node.PROCESS_MODE_ALWAYS
	asker.get_tree().current_scene.add_child(frame)


func _ready() -> void:
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cover.color = Color(ApolloPalette.OUTLINE, DARK_ALPHA)
	add_child(_cover)


func _process(_delta: float) -> void:
	_frames_shown += 1
	if _frames_shown == DARK_FRAMES:
		_cover.color = Color(ApolloPalette.WHITE, LIGHT_ALPHA)
	elif _frames_shown >= DARK_FRAMES + LIGHT_FRAMES:
		queue_free()
