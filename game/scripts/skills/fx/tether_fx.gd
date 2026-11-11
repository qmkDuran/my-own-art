class_name TetherFx
extends Node2D
## Tether's line of light: shoots out from the lantern to its end, holds for a moment, then is reeled back in,
## following the lantern as the Lamplighter moves.

const OUT_TIME: float = 0.08
const HOLD: float = 0.12
const BACK_TIME: float = 0.16
const WIDTH: float = 3.0

var player: Player
var end: Vector2
var _t: float = 0.0


static func cast(parent: Node, p: Player, to: Vector2) -> TetherFx:
	var f := TetherFx.new()
	f.player = p
	f.end = to
	f.material = Fx.glow_material()
	f.z_index = Fx.FX_Z
	parent.add_child(f)
	Fx.burst(parent, to, 6, Vector2(40, 110), 0.25, [Pal.c("sun"), Pal.c("gold"), Pal.c("amber", 0.0)])
	return f


func _process(delta: float) -> void:
	_t += delta
	if _t > OUT_TIME + HOLD + BACK_TIME or not is_instance_valid(player):
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var from: Vector2 = player.lantern_pos()
	var k: float = minf(1.0, _t / OUT_TIME) if _t < OUT_TIME + HOLD else 1.0 - (_t - OUT_TIME - HOLD) / BACK_TIME
	var tip: Vector2 = from.lerp(end, clampf(k, 0.0, 1.0))
	draw_line(from, tip, Pal.c("amber", 0.8), WIDTH * 2.0)
	draw_line(from, tip, Pal.c("sun"), WIDTH * 0.7)
	draw_circle(tip, WIDTH * 1.5, Pal.c("gold"))
