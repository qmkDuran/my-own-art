class_name UnseenTrainer
extends Trainer
## The trainer during play: not shown (their look is still undecided), but still throwing
## Trainer's Aid tonics. A tonic arcs in from just below the bottom edge of the screen,
## straight below Emberoo, as if thrown by someone standing out of view.
##
## Lives in the HUD so every zone has one; its own position is never used.

## How far below the screen's bottom edge the tonic starts, in screen pixels.
const BELOW_SCREEN_MARGIN := 6.0


## Just off the bottom of the screen, below the creature, turned into world coordinates.
func tonic_launch_point(at: Node2D) -> Vector2:
	var to_screen := get_viewport().get_canvas_transform()
	var screen_x := (to_screen * at.global_position).x
	var screen_bottom := get_viewport().get_visible_rect().size.y + BELOW_SCREEN_MARGIN
	return to_screen.affine_inverse() * Vector2(screen_x, screen_bottom)
