class_name EnemyTag
extends Node2D
## Above an enemy: a rare leader always shows its name with its modifiers (one per pack, so tags never pile up);
## a thin life bar shows on hurt elites and on the enemy under the cursor only (a pack never becomes a bar tangle).

const W: float = 26.0
const H: float = 2.0
const GAP: float = 6.0

var enemy: Enemy


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(enemy) or enemy.dead:
		return
	var top: float = -enemy.body_height() * 1.55 - GAP
	var shown: bool = enemy.rank != "normal" or Game.current.input.hovered_enemy == enemy
	if shown and enemy.life < enemy.max_life:
		var r := Rect2(-W / 2.0, top, W, H)
		draw_rect(r.grow(1.0), UiDraw.INK)
		draw_rect(Rect2(r.position, Vector2(W * enemy.life / enemy.max_life, H)), Pal.c("rose"))
	if enemy.rank != "rare":
		return
	UiDraw.text(self, Vector2(-100, top - 4.0), enemy.display_name(), Pal.c("gold"), UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, 200.0)
