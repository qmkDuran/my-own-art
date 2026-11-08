class_name PixelDigits
extends RefCounted
## A tiny 3×5 pixel font for numbers, drawn pixel by pixel so it stays crisp at any scale.
## Supports 0–9, '/', and the letters L and V (for "LV").

const GLYPH_WIDTH := 3
const GLYPH_HEIGHT := 5
## Pixels from one character's left edge to the next.
const ADVANCE := 4

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
	"L": ["#..", "#..", "#..", "#..", "###"],
	"V": ["#.#", "#.#", "#.#", "#.#", ".#."],
}


static func width_of(text: String) -> int:
	return maxi(0, text.length() * ADVANCE - 1)


## Draws the text with a dark outline so it reads on any background.
static func draw_text(canvas: CanvasItem, text: String, top_left: Vector2, color: Color, outline: Color) -> void:
	for pass_number in 2:
		for index in text.length():
			var glyph: Array = GLYPHS.get(text[index], [])
			var origin := top_left + Vector2(index * ADVANCE, 0)
			for y in glyph.size():
				for x in GLYPH_WIDTH:
					if glyph[y][x] != "#":
						continue
					if pass_number == 0:
						canvas.draw_rect(Rect2(origin + Vector2(x - 1, y - 1), Vector2(3, 3)), outline)
					else:
						canvas.draw_rect(Rect2(origin + Vector2(x, y), Vector2.ONE), color)
