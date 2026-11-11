class_name TitleScreen
extends Control
## The title: the dark, one lantern burning, embers rising, the name, and the menu (Continue / New Game / Quit).
## New Game plays the story cards (IntroCards: they type out and wait for a press; hold Esc to skip), then Tallow.

const BIG: int = 40
const ITEM_H: float = 22.0
const ITEM_W: float = 170.0
const EMBERS: int = 50
const GAME_SCENE: String = "res://scenes/game.tscn"
const FIGURE_SCALE: float = 2.0
const LIGHT_Y: float = 0.25
const LOGO_DROP: float = 155.0
const GLOW_R: float = 170.0
const GLOW_ALPHA: float = 0.2
const FADE_OUT: float = 1.2              ## after the last card, the screen goes to black before Tallow fades in

var _items: Array[String] = []
var _intro: IntroCards
var _t: float = 0.0
var _hover: int = -1
var _embers: CPUParticles2D
var _leaving: float = -1.0               ## counts up while fading to black after the cards


func _ready() -> void:
	GameData.ensure()
	InputSetup.ensure()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var straight_in: bool = args.has("--demo") or args.has("--demo2") or args.has("--demo3") or args.has("--balance") or args.has("--devtest") or args.has("--perf") or args.has("--animreel") or args.has("--smoke") or args.has("--play") or (args.has("--shots") and not args.has("--only=title") and not args.has("--only=intro"))
	if straight_in:
		get_tree().change_scene_to_file.call_deferred(GAME_SCENE)
		return
	if SaveGame.exists():
		_items.append("continue")
	_items.append_array(["new", "quit"])
	var holder := Node2D.new()
	add_child(holder)
	_embers = Fx.motes(holder, Vector2(300, 40), EMBERS, Pal.c("amber"))
	_embers.direction = Vector2.UP
	_embers.initial_velocity_min = 10.0
	_embers.initial_velocity_max = 26.0
	Audio.play_music("explore")


func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	_t += delta
	var vs: Vector2 = get_viewport_rect().size
	if _embers != null:
		(_embers.get_parent() as Node2D).position = Vector2(vs.x * 0.5, vs.y * 0.62)
	if _leaving >= 0.0:
		_leaving += delta
		queue_redraw()
		if _leaving >= FADE_OUT:
			Session.establishing = true
			get_tree().change_scene_to_file(GAME_SCENE)
		return
	if _intro != null:
		_intro.tick(delta)
		if _intro.done():
			_leaving = 0.0
			return
	_hover = -1
	for i: int in _items.size():
		if _item_rect(i).has_point(get_local_mouse_position()):
			_hover = i
	queue_redraw()


func _item_rect(i: int) -> Rect2:
	var vs: Vector2 = get_viewport_rect().size
	return Rect2(roundf((vs.x - ITEM_W) / 2.0), roundf(vs.y * 0.62) + i * (ITEM_H + 6.0), ITEM_W, ITEM_H)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if _intro != null:
		_intro.press()
	elif _hover >= 0:
		Audio.sfx("ui_click", -6.0)
		_choose(_items[_hover])


func _choose(id: String) -> void:
	match id:
		"continue":
			if not SaveGame.load_session():
				Session.reset()
			get_tree().change_scene_to_file(GAME_SCENE)
		"new":
			SaveGame.erase()
			Session.reset()
			_intro = IntroCards.new(GameData.story["intro"])
		"quit":
			get_tree().quit()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if _intro != null and k != null and k.pressed and not k.echo and k.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		_intro.press()


func _draw() -> void:
	var vs: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Pal.c("void"))
	var c := Vector2(vs.x * 0.5, vs.y * LIGHT_Y)
	var pulse: float = 1.0 + sin(_t * 2.1) * 0.04 + sin(_t * 7.0) * 0.015
	var r: float = GLOW_R * pulse                              # a smooth glow, no rings
	draw_texture_rect(LightTex.pool(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(Pal.c("amber"), GLOW_ALPHA))
	_draw_figure(c)
	if _leaving >= 0.0:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, clampf(_leaving / FADE_OUT, 0.0, 1.0)))
		return
	if _intro != null and not _intro.done():
		_draw_card(vs)
		return
	_draw_logo(c)
	for i: int in _items.size():
		_draw_item(i)
	UiDraw.text(self, Vector2(0, vs.y - 10.0), "a test slice  -  art and music made from code, some sounds CC0", UiDraw.DIM, UiDraw.SMALL,
		HORIZONTAL_ALIGNMENT_CENTER, vs.x)


## The Lamplighter, holding up the only light (his lantern sits where the glow is).
func _draw_figure(c: Vector2) -> void:
	var m: Dictionary = GameData.sprites["actors"]["lamplighter"]
	var frame: float = float(m["frame"][0])
	var k: int = int(_t * float(m["anims"]["idle"]["fps"])) % int(m["anims"]["idle"]["frames"])
	var a: Array = m["anims"]["idle"]["anchors"][0][k]              # facing us; the lantern sits where the glow is
	var in_sprite := Vector2(float(m["anchor"][0]) + float(a[0]), float(m["anchor"][1]) + float(a[1]))
	var dst := Rect2((c - in_sprite * FIGURE_SCALE).round(), Vector2(frame, frame) * FIGURE_SCALE)
	var src := Rect2(k * frame, 0, frame, frame)
	for layer: String in ["lamplighter", "lamplighter_lantern"]:
		draw_texture_rect_region(PropSprite.tex("res://art/actors/%s.png" % layer), dst, src, Color(0.45, 0.42, 0.55))
		draw_texture_rect_region(PropSprite.tex("res://art/actors/%s_glow.png" % layer), dst, src)


func _draw_logo(c: Vector2) -> void:
	var f: Font = UiDraw.font_for(self, UiDraw.TITLE)
	var s: String = "LANTERNFALL"
	var w: float = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, BIG).x
	var pos := Vector2(roundf(c.x - w / 2.0), roundf(c.y + LOGO_DROP))
	draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, BIG, 6, UiDraw.INK)
	draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, BIG, Pal.c("gold"))
	UiDraw.text(self, Vector2(0, c.y + LOGO_DROP + 20.0), "The sun went out three hundred years ago.", UiDraw.DIM, UiDraw.BODY,
		HORIZONTAL_ALIGNMENT_CENTER, get_viewport_rect().size.x)


func _draw_item(i: int) -> void:
	var r: Rect2 = _item_rect(i)
	var label: String = {"continue": "Continue", "new": "New Game", "quit": "Quit"}[_items[i]]
	UiDraw.box(self, r, Color(0.16, 0.1, 0.06) if i == _hover else Color(0.06, 0.05, 0.08), UiDraw.FRAME_LIT if i == _hover else UiDraw.FRAME)
	UiDraw.text(self, r.position + Vector2(0, 15), label, UiDraw.GOLD if i == _hover else UiDraw.TEXT, UiDraw.BODY,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _draw_card(vs: Vector2) -> void:
	_intro.draw(self, vs)
