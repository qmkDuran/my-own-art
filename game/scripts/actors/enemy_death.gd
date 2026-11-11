class_name EnemyDeath
extends RefCounted
## How a creature dies, scaled by its size and rank: the last hit flings it back (or it buckles where it stands),
## it flashes, then comes apart into ash (dark things) or shards (glass) with a burst of the light that killed it.
## It leaves an ash heap that lingers a few seconds; elites leave a bigger one with a ring of embers, bosses
## collapse slowly with three bursts and a long-lasting light.

const FLING: float = 34.0
const ASH_TIME: float = 4.0
const ELITE_RING: int = 10
const POSE: float = 0.3                 ## how long the death pose holds before it comes apart (x3 for bosses)
const FADE: float = 0.45                ## the body thins out while the ash and shards fly


static func play(e: Enemy, dir: Vector2) -> void:
	var g: Game = Game.current
	var size: float = e.sprite.scale.x * (2.2 if e.rank == "boss" else (1.4 if e.rank != "normal" else 1.0)) * (e.radius / 12.0)
	var at: Vector2 = e.global_position + Vector2(0, -e.body_height() * 0.4)
	var glass: bool = e.kind != "gloam" and e.kind != "moth"
	var boss: bool = e.rank == "boss"
	var tw := e.create_tween()
	var fling: Vector2 = dir.normalized() * FLING / maxf(1.0, size) if dir != Vector2.ZERO else Vector2.ZERO
	tw.set_parallel()                                           # the death pose: knocked back and down, flashing white
	var pose: float = POSE * (3.0 if boss else 1.0)
	tw.tween_property(e, "position", e.position + fling, pose * 0.6).set_ease(Tween.EASE_OUT)
	tw.tween_property(e.sprite, "rotation", 0.5 * signf(fling.x if fling.x != 0.0 else 1.0), pose * 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(e.sprite, "scale", Vector2(e.sprite.scale.x * 1.25, e.sprite.scale.y * 0.55), pose).set_ease(Tween.EASE_IN)
	(e.sprite.material as ShaderMaterial).set_shader_parameter("flash", 0.9)
	tw.chain().tween_callback(func() -> void: _dissolve(e, at, size, glass))
	tw.tween_property(e, "modulate:a", 0.0, FADE)
	tw.tween_callback(e.queue_free)
	Fx.flash(g.fx_layer, e.global_position, 70.0 * size, Pal.c("gold"), 1.2, 0.35)
	if boss:
		for k: int in 3:
			g.get_tree().create_timer(0.3 * (k + 1), false).timeout.connect(func() -> void:
				if is_instance_valid(g) and g == Game.current:          # the zone may have been left meanwhile
					Fx.death_burst(g.fx_layer, at + Vector2(randf_range(-30, 30), randf_range(-30, 10)), size * 0.7, glass))


static func _dissolve(e: Enemy, at: Vector2, size: float, glass: bool) -> void:
	var g: Game = Game.current
	if g == null:
		return
	Fx.death_burst(g.fx_layer, at, size, glass)
	Fx.burst(g.fx_layer, at, int(8 * size), Vector2(20, 60 * size), 1.1, [Pal.c("stone"), Pal.c("stone_dk"), Pal.c("ink", 0.0)],
		Vector2.UP, 180.0, Vector2(1.5, 2.5), false)                 # ash and debris
	_ash(e.global_position, size, e.rank != "normal")


## The heap left behind: dark ash with a few dying embers, fading after a few seconds.
static func _ash(at: Vector2, size: float, elite: bool) -> void:
	var g: Game = Game.current
	if g == null:
		return
	var heap := Node2D.new()
	heap.position = at
	heap.z_index = -13
	heap.z_as_relative = false
	var s := Sprite2D.new()
	s.texture = LightTex.shadow()
	s.scale = Vector2(size * 1.6, size * 0.9)
	s.modulate = Color(0.14, 0.12, 0.16, 0.9)
	heap.add_child(s)
	for k: int in (ELITE_RING if elite else 3):
		var em := Sprite2D.new()
		em.texture = LightTex.soft(8)
		em.material = Fx.glow_material()
		em.modulate = Pal.c("ember", 0.9)
		var a: float = TAU * (k + randf_range(-0.35, 0.35)) / (ELITE_RING if elite else 3)   # scattered, not a neat ring
		em.position = Vector2(cos(a) * 8.0, sin(a) * 4.0) * size * randf_range(0.4, 1.3)
		em.scale = Vector2.ONE * randf_range(0.5, 1.0)
		heap.add_child(em)
	g.fx_layer.add_child(heap)
	var tw := heap.create_tween()
	tw.tween_interval(ASH_TIME * (1.6 if elite else 1.0))
	tw.tween_property(heap, "modulate:a", 0.0, 1.0)
	tw.tween_callback(heap.queue_free)
