class_name EmberTreeIcons
extends RefCounted
## The Ember Tree's 8×8 pixel icons, and drawing them centred on a node.
##
## Icons are centred by their drawn pixels, not their 8×8 box, so lopsided
## shapes (a flame leaning right, a boot) still look centred in their frame.

const ICON_SIZE := 8
const FILLED := "#"

const PIXELS := {
	"fist": ["..###...", ".#####..", "########", "########", "#######.", ".######.", ".#####..", "..###..."],
	"flame": ["...#....", "..##....", "..###...", ".####.#.", ".######.", "########", "########", ".######."],
	"up": ["...##...", "..####..", ".######.", "...##...", "...##...", ".######.", "########", "########"],
	"hop": ["......#.", ".....##.", "....###.", "...#..#.", "..#.....", ".#......", "##......", "#......."],
	"star": ["...##...", "...##...", "########", ".######.", "..####..", ".##..##.", "##....##", "#......#"],
	"heart": [".##.##..", "#######.", "#######.", "#######.", ".#####..", "..###...", "...#....", "........"],
	"spark": ["#..#..#.", ".#.#.#..", "..###...", "#######.", "..###...", ".#.#.#..", "#..#..#.", "........"],
	"shield": ["########", "#.####.#", "########", "########", ".######.", ".######.", "..####..", "...##..."],
	"wave": ["..#...#.", "..#...##", ".##..###", ".###.###", "####.###", "########", "########", ".######."],
	"swirl": ["..####..", ".#....#.", "#..##..#", "#.#..#.#", "#.#.##.#", "#..#...#", ".#....#.", "..####.."],
	"hands": ["........", "##..###.", "....####", "###.####", "....####", "##..###.", "........", "........"],
	"boot": ["..###...", "..###...", "..###...", "..###...", "#.#####.", "..######", "#.######", "........"],
	"spring": ["########", "......#.", ".######.", ".#......", ".######.", "......#.", ".######.", "########"],
	"anchor": ["...##...", "..#..#..", "...##...", "...##...", "#..##..#", "##.##.##", ".######.", "..####.."],
	"sun": ["#..#..#.", ".#####..", ".#...#..", "##...##.", ".#...#..", ".#####..", "#..#..#.", "........"],
}

## Icon name -> middle of its drawn pixels, in icon pixels. Measured once, on first use.
static var _centres: Dictionary[String, Vector2] = {}


## Draws an icon so the middle of its drawn pixels sits exactly on `centre`.
static func draw(canvas: CanvasItem, icon_name: String, centre: Vector2, pixel_size: float, color: Color) -> void:
	var rows: Array = PIXELS.get(icon_name, PIXELS["star"])
	var top_left := centre - _centre_of(icon_name) * pixel_size
	for y in rows.size():
		for x in ICON_SIZE:
			if rows[y][x] == FILLED:
				canvas.draw_rect(Rect2(top_left + Vector2(x, y) * pixel_size, Vector2.ONE * pixel_size), color)


static func _centre_of(icon_name: String) -> Vector2:
	if not _centres.has(icon_name):
		_centres[icon_name] = _measure(PIXELS.get(icon_name, PIXELS["star"]))
	return _centres[icon_name]


static func _measure(rows: Array) -> Vector2:
	var low := Vector2(ICON_SIZE, ICON_SIZE)
	var high := Vector2(-1, -1)
	for y in rows.size():
		for x in ICON_SIZE:
			if rows[y][x] == FILLED:
				low = low.min(Vector2(x, y))
				high = high.max(Vector2(x, y))
	# +1: a pixel at x covers x..x+1, so the drawn area ends one past the last index.
	return (low + high + Vector2.ONE) / 2.0
