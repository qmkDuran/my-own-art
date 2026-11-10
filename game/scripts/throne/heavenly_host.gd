class_name HeavenlyHost
extends Node2D
## Myriads of angels round about the throne (Rev 5:11): far-off rows on the horizon of light, gently flapping.

const SHEET: String = "res://art/throne/angels_flap.png"   # one column per angel, 4 rows = wing-flap frames
const CELL: int = 32
const FLAP_FRAMES: int = 4
const PAD_TOP: int = 33                 # frames carry 3 px of padding above the 30 px figure
const CLEAR_HALF_WIDTH: float = 150.0   # no angels directly behind the throne
const STRIDE: int = 7                   # step through the angel columns for variety
const Z: int = -19
const FAR_TINT := Color(1.6, 1.6, 1.5)  # far off and bathed in light

var _angels: Array[Sprite2D] = []
var _base_y: Array[float] = []


func build(rows: Array, throne_x: float, rng: RandomNumberGenerator) -> void:
	var sheet: Texture2D = load(SHEET)
	var columns: int = sheet.get_width() / CELL
	var k: int = 0
	for row: Array in rows:
		var x: int = int(row[2])
		while x < 960:
			if absf(x + CELL / 2.0 - throne_x) >= CLEAR_HALF_WIDTH:
				_add(sheet, columns, k, Vector2(x, int(row[0]) - PAD_TOP), rng)
				k += STRIDE
			x += int(row[1])


func _add(sheet: Texture2D, columns: int, k: int, pos: Vector2, rng: RandomNumberGenerator) -> void:
	var a := Sprite2D.new()
	a.texture = sheet
	a.hframes = columns
	a.vframes = FLAP_FRAMES
	a.frame = k % columns
	a.set_meta("col", k % columns)
	a.set_meta("phase", rng.randf_range(0.0, 4.0))
	a.centered = false
	a.position = pos
	a.z_index = Z
	a.modulate = Color(FAR_TINT, 0.4 + 0.05 * (k % 3))
	add_child(a)
	_angels.append(a)
	_base_y.append(pos.y)


func animate(time: float) -> void:
	for i: int in _angels.size():
		var a: Sprite2D = _angels[i]
		a.position.y = _base_y[i] + roundf(sin(time * 1.4 + i * 0.7))
		a.frame = int(a.get_meta("col")) + (int(time * 4.0 + float(a.get_meta("phase"))) % FLAP_FRAMES) * a.hframes
