class_name EvolutionCeremony
extends RefCounted
## The short evolution ceremony (species "evolve"): the creature glows white and spins faster and faster while
## light gathers, a flash, and it stands there in its new, bigger form with its new name over it.

const SPIN_TIME: float = 1.2
const TURNS: int = 6
const GLOW := Color(2.2, 2.2, 2.2)


static func play(c: Creature) -> void:
	if c == null or not is_instance_valid(c):
		return
	var g: TamerGame = TamerGame.current
	var v: CreatureSprite = c.view
	c.size_k = c.size_now()
	var to_scale: Vector2 = Vector2.ONE * c.size_k
	Audio.sfx("lamp_lit", -4.0, 0.8)
	Fx.burst(g.fx_layer, c.global_position + Vector2(0, -14), 40, Vector2(30, 90), SPIN_TIME, [Pal.c("sun"), Pal.c("glint"), Pal.c("bone", 0.0)],
		Vector2.UP, 180.0)
	var tw: Tween = v.create_tween()
	tw.tween_property(v.sprite, "self_modulate", GLOW, SPIN_TIME * 0.3)
	for k: int in TURNS:
		var step: float = SPIN_TIME * 0.7 / TURNS * (1.0 - 0.1 * k)
		tw.tween_callback(func() -> void: v.sprite.flip_h = not v.sprite.flip_h)
		tw.tween_interval(step)
	tw.tween_callback(func() -> void:
		Fx.screen_flash(Pal.c("bone"), 0.25, 0.4)
		TamerFx.celebrate(c, c.element_id())
		TamerFx.word(c.global_position, "%s evolved into %s!" % [c.rec.data()["name"], c.rec.display_name()], Pal.c("gold"), UiDraw.TITLE))
	tw.tween_property(v, "scale", to_scale, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(v.sprite, "self_modulate", Color.WHITE, 0.3)
