class_name TitleScreen
extends Control
## The title: the dark, one lantern burning, embers rising, the name, and the menu (Continue / New Game / Quit).
## New Game plays four short story cards (click to skip ahead), then the Glasswood.

const BIG: int = 40
const ITEM_H: float = 22.0
const ITEM_W: float = 170.0
const CARD_TIME: float = 3.4
const EMBERS: int = 50
const GAME_SCENE: String = "res://scenes/game.tscn"
const FIGURE_SCALE: float = 2.0
const LANTERN_IN_SPRITE := Vector2(52, 10)
const FRAME: float = 64.0
const LIGHT_Y: float = 0.25
const LOGO_DROP: float = 155.0

var _items: Array[String] = []
var _cards: Array = []
var _card: int = -1
var _card_t: float = 0.0
var _t: float = 0.0
var _hover: int = -1
var _embers: CPUParticles2D


func _ready() -> void:
	GameData.ensure()
	InputSetup.ensure()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var straight_in: bool = args.has("--demo") or args.has("--demo2") or args.has("--smoke") or args.has("--play") or (args.has("--shots") and not args.has("--only=title"))
	if straight_in:
		get_tree().change_scene_to_file.call_deferred(GAME_SCENE)
		return
	if SaveGame.exists():
		_items.append("continue")
	_items.append_array(["new", "quit"])
	_cards = GameData.story["intro"]
	var holder := Node2D.new()
	add_child(holder)
	_embers = Fx.motes(holder, Vector2(300, 40), EMBERS, Pal.c("amber"))
	_embers.direction = Vector2.UP
	_embers.initial_velocity_min = 10.0
	_embers.initial_velocity_max = 26.0
	Audio.play_music("explore")


func _process(delta: float) -> void:
	_t += delta
	var vs: Vector2 = get_viewport_rect().size
	if _embers != null:
		(_embers.get_parent() as Node2D).position = Vector2(vs.x * 0.5, vs.y * 0.62)
	if _card >= 0:
		_card_t += delta
		if _card_t > CARD_TIME:
			_next_card()
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
	if _card >= 0:
		_next_card()
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
			_card = 0
			_card_t = 0.0
		"quit":
			get_tree().quit()


func _next_card() -> void:
	_card += 1
	_card_t = 0.0
	if _card >= _cards.size():
		get_tree().change_scene_to_file(GAME_SCENE)


func _draw() -> void:
	var vs: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Pal.c("void"))
	var c := Vector2(vs.x * 0.5, vs.y * LIGHT_Y)
	var pulse: float = 1.0 + sin(_t * 2.1) * 0.04 + sin(_t * 7.0) * 0.015
	for k: int in 6:
		draw_circle(c, (150.0 - k * 22.0) * pulse, Color(Pal.c("amber"), 0.035 + k * 0.02))
	_draw_figure(c)
	if _card >= 0:
		_draw_card(vs)
		return
	_draw_logo(c)
	for i: int in _items.size():
		_draw_item(i)
	UiDraw.text(self, Vector2(0, vs.y - 10.0), "a test slice  -  everything you see and hear is made from code", UiDraw.DIM, UiDraw.SMALL,
		HORIZONTAL_ALIGNMENT_CENTER, vs.x)


## The Lamplighter, holding up the only light (his lantern sits where the glow is).
func _draw_figure(c: Vector2) -> void:
	var tex: Texture2D = PropSprite.tex("res://art/actors/lamplighter.png")
	var glow: Texture2D = PropSprite.tex("res://art/actors/lamplighter_glow.png")
	var at: Vector2 = (c - LANTERN_IN_SPRITE * FIGURE_SCALE).round()
	var dst := Rect2(at, Vector2(FRAME, FRAME) * FIGURE_SCALE)
	var src := Rect2(int(_t * 5.0) % 4 * FRAME, 0, FRAME, FRAME)
	draw_texture_rect_region(tex, dst, src, Color(0.45, 0.42, 0.55))
	draw_texture_rect_region(glow, dst, src)


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
	var a: float = clampf(minf(_card_t, CARD_TIME - _card_t) * 2.0, 0.0, 1.0)
	var lines: PackedStringArray = UiDraw.wrap(self, String(_cards[_card]), vs.x * 0.6, UiDraw.TITLE)
	for i: int in lines.size():
		UiDraw.text(self, Vector2(0, vs.y * 0.62 + i * 26.0), lines[i], Color(UiDraw.TEXT, a), UiDraw.TITLE, HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	UiDraw.text(self, Vector2(0, vs.y - 12.0), "click to continue", Color(UiDraw.DIM, a), UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, vs.x)
