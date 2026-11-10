extends Node
## --compare: two screenshots for the Step 2 style test - Michael on the generated tiles beside the generated house
## (west), and on the reused Project R art (east) - into ../out/world_test_{generated,reused}.png. Needs a display.

const SPOTS: Array = [["generated", Vector2(470, 560)], ["reused", Vector2(1200, 560)]]

var _t: float = 0.0
var _i: int = 0


func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--compare"):
		set_process(false)


func _process(delta: float) -> void:
	_t += delta
	var g := get_tree().current_scene as Game
	if g == null or _t < 1.0:
		return
	if _i >= SPOTS.size():
		get_tree().quit()
		return
	for d: Node in get_tree().get_nodes_in_group("demons"):
		(d as Node2D).visible = false
	g.michael.position = SPOTS[_i][1]
	g.camera.reset_smoothing()
	if _t > 2.5 + _i * 1.5:
		var img: Image = get_viewport().get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("res://") + "../out/world_test_%s.png" % SPOTS[_i][0])
		print("SHOT ", SPOTS[_i][0])
		_i += 1
