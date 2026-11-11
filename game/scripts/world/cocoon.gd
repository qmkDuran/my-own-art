class_name Cocoon
extends Interactable
## Nim, held in glass by the Glazier. The glass holds while the Glazier stands; when it falls, the shell breaks
## and Nim steps out.

signal freed

var broken: bool = false


func _ready() -> void:
	title = "A child in glass"
	super()


func use(g: Game) -> void:
	if not broken:
		g.hud.caption("The glass won't break while the Glazier stands.")


## Already broken (a later visit): no burst, no sound.
func open_quietly() -> void:
	broken = true
	title = ""
	PropSprite.set_frame(sprite, 1)


func shatter(g: Game) -> void:
	if broken:
		return
	broken = true
	title = ""
	PropSprite.set_frame(sprite, 1)
	Audio.sfx("die_glass", -2.0, 0.7)
	Fx.burst(g.fx_layer, global_position + Vector2(0, -30), 40, Vector2(60, 220), 0.8,
		[Pal.c("glint"), Pal.c("glass_lt"), Pal.c("glass", 0.0)], Vector2.UP, 180.0, Vector2(1, 2))
	Fx.flash(g.fx_layer, global_position, 200.0, Pal.c("glint"), 1.6, 0.6)
	freed.emit()
