class_name PixelFont
extends RefCounted
## A tiny 5-pixel-tall font for the HUD, drawn pixel by pixel so it stays crisp at any scale.
## Has the digits, '/', '.', brackets, a space, every capital A-Z (for LV, N for north, the
## training dummy's combo total, the debug banner, and whatever keys the skills and Trainer's
## Aid are bound to), '!' for critical-hit numbers and '+' (the debug banner's "+5").
## Glyphs can be 1 to 5 pixels wide.

const GLYPH_HEIGHT := 5
## Empty pixels between two characters.
const LETTER_GAP := 1

const GLYPHS := {
	"0": ["###", "#.#", "#.#", "#.#", "###"],
	"1": [".#.", "##.", ".#.", ".#.", "###"],
	"2": ["###", "..#", "###", "#..", "###"],
	"3": ["###", "..#", "###", "..#", "###"],
	"4": ["#.#", "#.#", "###", "..#", "..#"],
	"5": ["###", "#..", "###", "..#", "###"],
	"6": ["###", "#..", "###", "#.#", "###"],
	"7": ["###", "..#", ".#.", ".#.", ".#."],
	"8": ["###", "#.#", "###", "#.#", "###"],
	"9": ["###", "#.#", "###", "..#", "###"],
	"/": ["..#", "..#", ".#.", "#..", "#.."],
	" ": [".", ".", ".", ".", "."],
	"L": ["#..", "#..", "#..", "#..", "###"],
	"V": ["#.#", "#.#", "#.#", "#.#", ".#."],
	"Q": [".##.", "#..#", "#..#", "#.#.", ".#.#"],
	"W": ["#...#", "#...#", "#.#.#", "#.#.#", ".#.#."],
	"E": ["###", "#..", "##.", "#..", "###"],
	"R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"F": ["###", "#..", "##.", "#..", "#.."],
	"N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
	"A": [".#.", "#.#", "###", "#.#", "#.#"],
	"D": ["##.", "#.#", "#.#", "#.#", "##."],
	"I": ["###", ".#.", ".#.", ".#.", "###"],
	"M": ["#...#", "##.##", "#.#.#", "#...#", "#...#"],
	"O": [".#.", "#.#", "#.#", "#.#", ".#."],
	"P": ["##.", "#.#", "##.", "#..", "#.."],
	"S": [".##", "#..", ".#.", "..#", "##."],
	"T": ["###", ".#.", ".#.", ".#.", ".#."],
	"U": ["#.#", "#.#", "#.#", "#.#", "###"],
	"B": ["##.", "#.#", "##.", "#.#", "##."],
	"C": [".##", "#..", "#..", "#..", ".##"],
	"G": [".##", "#..", "#.#", "#.#", ".##"],
	"H": ["#.#", "#.#", "###", "#.#", "#.#"],
	"J": ["..#", "..#", "..#", "#.#", ".#."],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"],
	"X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
	"Z": ["###", "..#", ".#.", "#..", "###"],
	".": [".", ".", ".", ".", "#"],
	"!": ["#", "#", "#", ".", "#"],
	"+": ["...", ".#.", "###", ".#.", "..."],
	"(": [".#", "#.", "#.", "#.", ".#"],
	")": ["#.", ".#", ".#", ".#", "#."],
}


## Width in pixels of the text as drawn (without its outline).
static func width_of(text: String) -> int:
	var width := 0
	for character in text:
		width += _glyph_width(character) + LETTER_GAP
	return maxi(0, width - LETTER_GAP)


## Draws the text with a dark outline (all 8 neighbours) so it reads on any background.
static func draw_text(canvas: CanvasItem, text: String, top_left: Vector2, color: Color, outline: Color) -> void:
	var pixels := _text_pixels(text, top_left)
	for pixel in pixels:
		canvas.draw_rect(Rect2(pixel - Vector2.ONE, Vector2(3, 3)), outline)
	for pixel in pixels:
		canvas.draw_rect(Rect2(pixel, Vector2.ONE), color)


## Every lit pixel of the text, in canvas coordinates.
static func _text_pixels(text: String, top_left: Vector2) -> Array[Vector2]:
	var pixels: Array[Vector2] = []
	var left := top_left.x
	for character in text:
		var glyph: Array = GLYPHS.get(character, [])
		for y in glyph.size():
			for x in glyph[y].length():
				if glyph[y][x] == "#":
					pixels.append(Vector2(left + x, top_left.y + y))
		left += _glyph_width(character) + LETTER_GAP
	return pixels


static func _glyph_width(character: String) -> int:
	var glyph: Array = GLYPHS.get(character, ["..."])
	return glyph[0].length()
