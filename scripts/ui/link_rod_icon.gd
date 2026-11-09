class_name LinkRodIcon
extends Control
## The Link Rod itself, drawn big: the stolen Warden rod (art/ui/link_rod.png) with its four
## chip sockets lit by what is in them. A socket with a chip glows cyan, an open empty one
## glows faintly, and one the rod hasn't got yet (more come from Glimmer Shards) stays dark.

const TEXTURE := preload("res://art/ui/link_rod.png")
## Screen pixels per art pixel.
const ART_SCALE := 4
## The sockets' insides in the art, left to right (slot 0 first).
const SOCKETS: Array[Rect2i] = [Rect2i(16, 7, 5, 4), Rect2i(26, 7, 5, 4), Rect2i(36, 7, 5, 4), Rect2i(46, 7, 5, 4)]
const PULSE_SECONDS := 1.6

var _age: float = 0.0


func _init() -> void:
	custom_minimum_size = TEXTURE.get_size() * ART_SCALE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()


func _draw() -> void:
	var origin := ((size - custom_minimum_size) / 2.0).round()
	draw_texture_rect(TEXTURE, Rect2(origin, custom_minimum_size), false)
	var pulse := 0.5 - 0.5 * cos(TAU * _age / PULSE_SECONDS)
	for slot_index in SOCKETS.size():
		_draw_socket(origin, SOCKETS[slot_index], slot_index, pulse)


func _draw_socket(origin: Vector2, socket: Rect2i, slot_index: int, pulse: float) -> void:
	var rect := Rect2(origin + Vector2(socket.position) * ART_SCALE, Vector2(socket.size) * ART_SCALE)
	if slot_index >= LinkRod.slot_count():
		# Not unlocked: a small dark cross.
		var centre := rect.get_center()
		draw_line(centre - Vector2(4, 4), centre + Vector2(4, 4), ApolloPalette.STONE, 2.0)
		draw_line(centre + Vector2(-4, 4), centre + Vector2(4, -4), ApolloPalette.STONE, 2.0)
	elif LinkRod.chip_in_slot(slot_index) != null:
		draw_rect(rect.grow(2), Color(LinkRodPalette.CHIP, 0.25 + 0.2 * pulse))
		draw_rect(rect, LinkRodPalette.CHIP)
		draw_rect(Rect2(rect.position, Vector2(ART_SCALE * 2, ART_SCALE)), LinkRodPalette.CHIP_LIGHT)
	else:
		draw_rect(rect, Color(LinkRodPalette.CHIP_DIM, 0.35 + 0.25 * pulse))
