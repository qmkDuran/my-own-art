class_name PropSprite
extends RefCounted
## Sprites for props and actors from the generated sheets: anchored at the bottom centre (the ground contact the
## layout uses), with the emissive layer added on top unlit, so glints and lamp panes glow in the dark.

static var _tex: Dictionary = {}


static func tex(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]


static func make(kind: String, frame: int = 0) -> Sprite2D:
	var meta: Dictionary = GameData.props[kind]
	var s := Sprite2D.new()
	s.texture = tex("res://art/props/%s.png" % kind)
	s.hframes = int(meta["frames"])
	s.frame = frame
	s.offset = Vector2(0, -float(meta["size"][1]) / 2.0)
	add_glow(s, "res://art/props/%s_glow.png" % kind)
	return s


## Adds the emissive twin of a sprite (same frames, additive and unlit) if that layer exists.
static func add_glow(s: Sprite2D, path: String) -> Sprite2D:
	var t: Texture2D = tex(path)
	if t == null:
		return null
	var g := Sprite2D.new()
	g.texture = t
	g.hframes = s.hframes
	g.vframes = s.vframes
	g.frame = s.frame
	g.offset = s.offset
	g.material = Fx.glow_material()
	g.name = "Glow"
	s.add_child(g)
	return g


static func set_frame(s: Sprite2D, f: int) -> void:
	s.frame = f
	var g: Sprite2D = s.get_node_or_null("Glow") as Sprite2D
	if g != null:
		g.frame = f
		g.flip_h = s.flip_h


## A soft dark ellipse that grounds a body or prop on the floor.
static func shadow(width: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = LightTex.shadow()
	s.scale = Vector2(width / LightTex.SHADOW_SIZE, width * 0.4 / LightTex.SHADOW_SIZE)
	s.z_index = -1
	s.z_as_relative = true
	s.show_behind_parent = true
	return s
