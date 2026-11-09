class_name ImpactFrame
extends CanvasLayer
## The impact frame on a reaction finisher: for one real frame the whole screen drops to a
## dark wash, then one frame of a pale flash, then it's gone. Counted in rendered frames, so a
## hit-stop doesn't stretch it.

const DARK_FRAMES := 1
const LIGHT_FRAMES := 1
const DARK_ALPHA := 0.8
const LIGHT_ALPHA := 0.5

var _cover := ColorRect.new()
var _frames_shown: int = 0


static func play(asker: Node) -> void:
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
