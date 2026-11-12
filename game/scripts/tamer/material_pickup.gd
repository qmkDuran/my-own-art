class_name MaterialPickup
extends Node2D
## A material a wild creature dropped: it pops out, lands, glints in its colour, and flies to the trainer when they
## come near (no clicking needed: the grind should never be a chore).

const POP_HEIGHT: float = 18.0
const POP_TIME: float = 0.35
const PULL_RANGE: float = 420.0         ## they find the trainer after a fight (who stays back)
const PULL_SPEED: float = 380.0
const TAKE_RANGE: float = 12.0
const GEM: float = 3.5

var material_id: String
var amount: int = 1
var _landed: bool = false
var _t: float = 0.0


static func drop(g: TamerGame, at: Vector2, id: String, n: int) -> MaterialPickup:
	var p := MaterialPickup.new()
	p.material_id = id
	p.amount = n
	p.add_to_group("material_drops")
	p.position = at
	g.world.add_child(p)
	var land: Vector2 = g.layout.free_spot_near(at + Vector2(randf_range(-22, 22), randf_range(-8, 14)), 4.0)
	var tw := p.create_tween()
	tw.tween_property(p, "position", land, POP_TIME).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_method(func(k: float) -> void:
		p.queue_redraw()
		p.set_meta("lift", sin(k * PI) * POP_HEIGHT), 0.0, 1.0, POP_TIME)
	tw.tween_callback(func() -> void: p._landed = true)
	return p


func color() -> Color:
	return Pal.c(String(TamerData.rule("materials." + material_id + ".color")))


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if not _landed:
		return
	var tr: Trainer = TamerGame.current.trainer
	var d: float = global_position.distance_to(tr.global_position)
	if d < PULL_RANGE:
		global_position = global_position.move_toward(tr.global_position, PULL_SPEED * delta)
		if d < TAKE_RANGE:
			_take()


func _take() -> void:
	TamerGame.current.team.add_material(material_id, amount)
	TamerFx.word(global_position, "+%d %s" % [amount, String(TamerData.rule("materials." + material_id + ".name"))], color())
	Audio.sfx("pickup", -8.0, 1.2)
	queue_free()


func _draw() -> void:
	var lift: float = float(get_meta("lift", 0.0)) + (sin(_t * 4.0) * 1.5 if _landed else 0.0)
	var top := Vector2(0, -6.0 - lift)
	draw_circle(Vector2(0, 1), GEM + 1.0, Color(0, 0, 0, 0.35))
	var pts := PackedVector2Array([top + Vector2(0, -GEM), top + Vector2(GEM, 0), top + Vector2(0, GEM), top + Vector2(-GEM, 0)])
	draw_colored_polygon(pts, color())
	draw_polyline(pts + PackedVector2Array([pts[0]]), Pal.c("void"), 1.0)
	draw_rect(Rect2(top + Vector2(-1, -2), Vector2(1, 1)), Pal.c("sun"))
	if int(_t * 3.0) % 3 == 0:
		draw_rect(Rect2(top + Vector2(2, -4), Vector2(1, 1)), Pal.c("sun"))
