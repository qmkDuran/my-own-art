class_name SkillIcons
extends RefCounted
## Small hand-drawn skill glyphs (original): a blade, a descending arrow, sound waves, a shield, a horn, a radiant sun.


static func draw_icon(ci: CanvasItem, id: String, c: Vector2, col: Color) -> void:
	var gold := Color("f9c22b") * col
	var pale := Color("fbff86") * col
	match id:
		"strike":
			ci.draw_line(c + Vector2(-10, 10), c + Vector2(9, -9), pale, 3.0)
			ci.draw_line(c + Vector2(-7, 3), c + Vector2(-3, 7), gold, 3.0)
		"descent":
			ci.draw_line(c + Vector2(0, -11), c + Vector2(0, 6), pale, 3.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-7, 4), c + Vector2(7, 4), c + Vector2(0, 12)]), gold)
		"rebuke":
			for i: int in 3:
				ci.draw_arc(c + Vector2(-8, 0), 5.0 + i * 5.0, -0.8, 0.8, 8, pale if i == 0 else gold, 2.0)
		"shield":
			ci.draw_circle(c, 11.0, Color("4d65b4") * col)
			ci.draw_arc(c, 11.0, 0.0, TAU, 20, gold, 2.0)
			ci.draw_line(c + Vector2(0, -8), c + Vector2(0, 8), gold, 2.0)
			ci.draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), gold, 2.0)
		"trumpet":
			ci.draw_line(c + Vector2(-10, 4), c + Vector2(4, -4), gold, 3.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(2, -8), c + Vector2(11, -11), c + Vector2(8, 2)]), pale)
		"radiance":
			ci.draw_circle(c, 5.0, pale)
			for i: int in 8:
				var a: float = TAU * i / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * 8.0, c + Vector2(cos(a), sin(a)) * 12.0, gold, 2.0)
