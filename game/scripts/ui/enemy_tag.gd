class_name EnemyTag
extends Node2D
## Above an enemy: elites always show their name (blue magic, gold rare) with modifiers; anyone hurt shows a thin
## life bar. Unlit, on the overlay, so it reads in the dark.

const W: float = 26.0
const H: float = 3.0
const GAP: float = 6.0

var enemy: Enemy


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(enemy) or enemy.dead:
		return
	var top: float = -enemy.body_height() * 1.55 - GAP
	if enemy.life < enemy.max_life:
		var r := Rect2(-W / 2.0, top, W, H)
		draw_rect(r.grow(1.0), UiDraw.INK)
		draw_rect(Rect2(r.position, Vector2(W * enemy.life / enemy.max_life, H)), Pal.c("rose"))
	if enemy.rank == "normal":
		return
	var col: Color = Pal.c("gold") if enemy.rank == "rare" else Color("7fb2ff")
	UiDraw.text(self, Vector2(-100, top - 4.0), enemy.display_name(), col, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, 200.0)
