class_name HudGlyphs
## The ability glyphs, drawn in code on a Control: bold simple shapes in each ability's colour, given in unit
## coordinates (scaled by the glyph size): filled dots [x, y, radius], filled polygons and lines.

const WIDTH: float = 3.0
const RAYS: int = 8
const RAY_FROM: float = 0.65
const DOTS: Dictionary = {
	"primary": [[0.25, 0.0, 0.35]], "heavy": [[-1.0, 0.0, 0.4]], "bomb": [[0.0, 0.15, 0.62]],
	"super": [[0.0, 0.0, 0.5]],
}
const POLYGONS: Dictionary = {
	"heavy": [[[-1.0, -0.22], [1.0, -0.12], [1.0, 0.12], [-1.0, 0.22]]],
}
const LINES: Dictionary = {
	"primary": [[[-1.0, 0.0], [0.1, 0.0]], [[-0.8, -0.35], [0.0, 0.0], [-0.8, 0.35]]],
	"bomb": [[[0.0, -0.45], [0.4, -1.0]]],
	"ward": [[[0.0, -1.0], [0.87, -0.5], [0.87, 0.5], [0.0, 1.0], [-0.87, 0.5], [-0.87, -0.5], [0.0, -1.0]]],
	"blink": [[[-0.5, -0.6], [0.0, 0.0], [-0.5, 0.6]], [[0.3, -0.6], [0.8, 0.0], [0.3, 0.6]]],
}


static func draw(canvas: Control, ability: String, at: Vector2, size: float, colour: Color) -> void:
	for dot: Array in DOTS.get(ability, []):
		canvas.draw_circle(at + Vector2(float(dot[0]), float(dot[1])) * size, float(dot[2]) * size, colour)
	for polygon: Array in POLYGONS.get(ability, []):
		canvas.draw_colored_polygon(_points(polygon, at, size), colour)
	for line: Array in LINES.get(ability, []):
		canvas.draw_polyline(_points(line, at, size), colour, WIDTH, true)
	if ability == "super":
		for index: int in RAYS:
			var direction := Vector2.from_angle(TAU * index / RAYS)
			canvas.draw_line(at + direction * size * RAY_FROM, at + direction * size, colour, WIDTH, true)


static func _points(shape: Array, at: Vector2, size: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Array in shape:
		out.append(at + Vector2(float(point[0]), float(point[1])) * size)
	return out
