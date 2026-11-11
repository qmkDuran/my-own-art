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
const POP_FLARE: float = 170.0          ## the death's light flare radius (x size): it lights the area for an instant
const POP_FLARE_TIME: float = 0.3
const DEBRIS: int = 9                   ## bits of ash and glass per unit of size
const DEBRIS_REACH := Vector2(18.0, 52.0)
const DEBRIS_HOP := Vector2(14.0, 34.0)
const DEBRIS_FALL: float = 0.55


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
	(e.sprite.material as ShaderMaterial).set_shader_parameter("flash_color", Enemy.WHITE)
	(e.sprite.material as ShaderMaterial).set_shader_parameter("flash", 1.0)
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
	Fx.core(g.fx_layer, at, 34.0 * size, 0.05)
	Fx.ring(g.fx_layer, e.global_position, 12.0, 70.0 * size, Color(Pal.c("sun"), 0.8), 0.32)
	Fx.flash(g.fx_layer, e.global_position, POP_FLARE * size, Pal.c("gold"), 3.0, POP_FLARE_TIME)
	_debris(g, e.global_position, at, size, glass)
	Fx.burst(g.fx_layer, at, int(8 * size), Vector2(20, 60 * size), 1.1, [Pal.c("stone"), Pal.c("stone_dk"), Pal.c("ink", 0.0)],
		Vector2.UP, 180.0, Vector2(1.5, 2.5), false)                 # ash and debris
	_ash(e.global_position, size, e.rank != "normal")


## Bits of ash (and glass, for glass things) thrown out of the body: each arcs up, lands and bounces, lies there
## with the ash heap, then fades.
static func _debris(g: Game, ground: Vector2, from: Vector2, size: float, glass: bool) -> void:
	for i: int in int(DEBRIS * size):
		var bit := Sprite2D.new()
		bit.texture = PropSprite.tex(Fx.SPARK)
		var shard: bool = glass and i % 2 == 0
		bit.modulate = Pal.c("glass_lt") if shard else Pal.c("stone_dk").lerp(Pal.c("ink"), randf())
		bit.material = Fx.unshaded() if shard else null
		bit.scale = Vector2(randf_range(1.0, 2.2), randf_range(0.8, 1.6))
		bit.rotation = randf() * TAU
		bit.position = from
		bit.z_index = -12
		bit.z_as_relative = false
		g.fx_layer.add_child(bit)
		var land: Vector2 = ground + Vector2(randf_range(-1, 1) * randf_range(DEBRIS_REACH.x, DEBRIS_REACH.y) * size, randf_range(-6, 10))
		var tw := bit.create_tween().set_parallel()
		tw.tween_property(bit, "position:x", land.x, DEBRIS_FALL)
		tw.tween_property(bit, "rotation", bit.rotation + randf_range(-6, 6), DEBRIS_FALL)
		var up := bit.create_tween()
		up.tween_property(bit, "position:y", from.y - randf_range(DEBRIS_HOP.x, DEBRIS_HOP.y), DEBRIS_FALL * 0.3).set_ease(Tween.EASE_OUT)
		up.tween_property(bit, "position:y", land.y, DEBRIS_FALL * 0.7).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		up.tween_interval(ASH_TIME * randf_range(0.8, 1.2))
		up.tween_property(bit, "modulate:a", 0.0, 1.0)
		up.tween_callback(bit.queue_free)


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
