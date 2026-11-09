class_name FxPixels
extends RefCounted
## Drawing helpers for the code-drawn attack effects (ImpactEffect, CritFlare, the Ember Hop
## landing...): filled discs, flat rings, thick lines and star flashes, all built from whole
## world pixels so they stay crisp at any window size. Pass whole-pixel centres.

## How flat a ring lying on the ground is drawn (the view looks down at the ground at a slant).
const GROUND_SQUASH := 0.5


## A filled disc `radius` pixels round `centre`, one rectangle per row.
static func draw_disc(canvas: CanvasItem, centre: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		canvas.draw_rect(Rect2(centre, Vector2.ONE), color)
		return
	var rows := ceili(radius)
	for row in range(-rows, rows):
		var half_width := roundi(sqrt(maxf(0.0, radius * radius - (row + 0.5) * (row + 0.5))))
		if half_width > 0:
			canvas.draw_rect(Rect2(centre.x - half_width, centre.y + row, half_width * 2, 1), color)


## A ring between `inner` and `outer` pixels round `centre`, flattened by `squash` (1 = round,
## GROUND_SQUASH for a ring lying on the ground).
static func draw_ring(canvas: CanvasItem, centre: Vector2, outer: float, inner: float, color: Color, squash: float = 1.0) -> void:
	var rows := ceili(outer * squash)
	for row in range(-rows, rows):
		var height := (row + 0.5) / squash
		var outer_half := roundi(sqrt(maxf(0.0, outer * outer - height * height)))
		if outer_half <= 0:
			continue
		var inner_half := roundi(sqrt(maxf(0.0, inner * inner - height * height))) if absf(height) < inner else 0
		var y := centre.y + row
		if inner_half <= 0:
			canvas.draw_rect(Rect2(centre.x - outer_half, y, outer_half * 2, 1), color)
			continue
		canvas.draw_rect(Rect2(centre.x - outer_half, y, outer_half - inner_half, 1), color)
		canvas.draw_rect(Rect2(centre.x + inner_half, y, outer_half - inner_half, 1), color)


## A line `thickness` pixels wide (a square brush stamped every pixel along it).
static func draw_thick_line(canvas: CanvasItem, from: Vector2, to: Vector2, thickness: int, color: Color) -> void:
	var steps := maxi(1, ceili(from.distance_to(to)))
	var brush := Vector2.ONE * thickness
	var half := Vector2.ONE * floorf(thickness / 2.0)
	for step in steps + 1:
		var at := from.lerp(to, float(step) / steps).round() - half
		canvas.draw_rect(Rect2(at, brush), color)


## A four-pointed star flash: long arms across and up-down, `arm` pixels from the centre,
## and diagonals half as long. Arms are 1 pixel wide past the 3×3 heart.
static func draw_star(canvas: CanvasItem, centre: Vector2, arm: int, color: Color) -> void:
	canvas.draw_rect(Rect2(centre.x - arm, centre.y, arm * 2 + 1, 1), color)
	canvas.draw_rect(Rect2(centre.x, centre.y - arm, 1, arm * 2 + 1), color)
	canvas.draw_rect(Rect2(centre - Vector2.ONE, Vector2(3, 3)), color)
	for diagonal in range(1, ceili(arm / 2.0) + 1):
		for corner: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			canvas.draw_rect(Rect2(centre + corner * diagonal, Vector2.ONE), color)


## A steady random 0..1 for a pixel (or any three whole numbers), so flicker jumps, not crawls.
static func noise(a: int, b: int, c: int) -> float:
	return float(absi(hash(Vector3i(a, b, c))) % 1000) / 1000.0


## The colour `heat_lost` (0 hottest, 1 coolest) of the way down a hottest-first `ramp`.
static func ramp_color(ramp: Array[Color], heat_lost: float) -> Color:
	return ramp[clampi(floori(heat_lost * ramp.size()), 0, ramp.size() - 1)]
