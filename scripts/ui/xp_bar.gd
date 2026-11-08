class_name XpBar
extends Control
## A thin XP bar along the bottom of the screen, with the level shown at its left end.
## Flashes bright when the player levels up.

@export var empty_color: Color = Color(0.063, 0.078, 0.122)       # Apollo 10141f
@export var fill_color: Color = Color(0.871, 0.62, 0.255)         # Apollo de9e41
@export var shine_color: Color = Color(0.91, 0.757, 0.439)        # Apollo e8c170
@export var outline_color: Color = Color(0.035, 0.039, 0.078)     # Apollo 090a14
@export var label_color: Color = Color(0.906, 0.835, 0.702)       # Apollo e7d5b3
## Height of the bar itself, in game pixels.
const BAR_HEIGHT := 2.0

var _flash: float = 0.0


func _ready() -> void:
	Progression.xp_changed.connect(func(_xp: int, _next: int) -> void: queue_redraw())
	Progression.leveled_up.connect(_on_leveled_up)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 2.0)
		queue_redraw()


func _on_leveled_up(_level: int) -> void:
	_flash = 1.0
	queue_redraw()


func _draw() -> void:
	var label := "LV%d" % Progression.level
	var label_width := PixelDigits.width_of(label)
	var bar_left := label_width + 3.0
	var bar := Rect2(Vector2(bar_left, (size.y - BAR_HEIGHT) / 2.0), Vector2(size.x - bar_left, BAR_HEIGHT))
	PixelDigits.draw_text(self, label, Vector2(0, roundf((size.y - PixelDigits.GLYPH_HEIGHT) / 2.0)), label_color, outline_color)
	draw_rect(bar.grow(1.0), outline_color)
	draw_rect(bar, empty_color)
	var share := float(Progression.xp) / float(maxi(1, Progression.xp_to_next()))
	var filled := Rect2(bar.position, Vector2(roundf(bar.size.x * share), bar.size.y))
	draw_rect(filled, fill_color.lerp(Color.WHITE, _flash * 0.6))
	draw_rect(Rect2(filled.position, Vector2(filled.size.x, 1)), shine_color)
