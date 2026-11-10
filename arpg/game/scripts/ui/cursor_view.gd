class_name CursorView
extends Control
## The pointer, drawn by the game (above every panel): a small gold arrow; over an enemy it turns into a sword mark.
## In the recorded demo it shows the bot's virtual cursor, so the video shows the controls being used.

var game: Game


func setup(g: Game) -> void:
	game = g
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var p: Vector2 = game.cursor_screen() if game.cursor_override != Vector2.INF else get_viewport().get_mouse_position()
	var on_enemy: bool = game.demon_near(game.mouse_world(), Game.TARGET_RADIUS) != null
	var col := Color("e83b3b") if on_enemy else Color("fbff86")
	if game.lmb:
		draw_circle(p, 5.0, Color(col, 0.35))
	var arrow := PackedVector2Array([p, p + Vector2(0, 13), p + Vector2(4, 9), p + Vector2(7, 15), p + Vector2(9, 14),
		p + Vector2(6, 8), p + Vector2(11, 8)])
	draw_colored_polygon(arrow, col)
	draw_polyline(arrow + PackedVector2Array([p]), UiDraw.INK, 1.0)
