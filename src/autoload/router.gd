extends CanvasLayer
## Scene flow: menu <-> game, zone transitions with fades, title / time-skip cards, retry.
## Owns the full-screen fade overlay so it survives scene changes.

signal game_registered

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"
const FADE_TIME := 0.45
const CARD_HOLD := 2.2

var game: Game
var ui_modal := false

var _busy := 0
var _show_intro_card := false
var _fade_rect: ColorRect
var _card_title: Label
var _card_subtitle: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_rect = _make_fade_rect()
	add_child(_fade_rect)
	_card_title = _make_card_label(34, 220)
	_card_subtitle = _make_card_label(18, 280)
	add_child(_card_title)
	add_child(_card_subtitle)
	Events.player_died.connect(retry_from_checkpoint)


## True while gameplay input should be ignored (dialogue, fades, cards, menus).
func is_gameplay_paused() -> bool:
	return _busy > 0 or ui_modal or Dialogue.is_running() or Dialogue.just_finished()


func is_busy() -> bool:
	return _busy > 0


# --- Flow --------------------------------------------------------------------

func start_new_game(gender: String, skin_tone: int = 2, hair_style: String = "") -> void:
	GameState.new_game(gender, skin_tone, hair_style)
	_show_intro_card = true
	await _enter_game()


func continue_game() -> void:
	if not GameState.load_save():
		return
	_show_intro_card = false
	await _enter_game()


## Quits cleanly: stops audio first so no playback is left alive at exit.
func quit_game() -> void:
	AudioManager.shutdown()
	for i in 5:
		await get_tree().process_frame
	get_tree().quit()


func return_to_menu() -> void:
	_busy += 1
	await fade_out()
	AudioManager.stop_music(1.0)
	AudioManager.set_ambience([], 1.0)
	game = null
	get_tree().change_scene_to_file(MENU_SCENE)
	await get_tree().process_frame
	await fade_in()
	_busy -= 1


## Called by Game._ready. Standalone runs of game.tscn start a default new game.
func register_game(new_game: Game) -> void:
	game = new_game
	if GameState.zone_id.is_empty():
		GameState.new_game("female")
	game_registered.emit()
	if _busy == 0:
		_load_current_zone.call_deferred()


func go_to_zone(zone_id: String, spawn_id: String) -> void:
	_busy += 1
	AudioManager.play_sfx("door_open")
	await fade_out()
	GameState.zone_id = zone_id
	GameState.spawn_id = spawn_id
	GameState.spawn_position = null
	game.load_zone(zone_id, spawn_id, null)
	GameState.save_checkpoint()
	await fade_in()
	_busy -= 1
	game.run_zone_entry_scripts()


func retry_from_checkpoint() -> void:
	_busy += 1
	await get_tree().create_timer(1.2).timeout
	await fade_out(0.8)
	HitStop.reset()
	GameState.restore_checkpoint()
	if game:
		game.load_zone(GameState.zone_id, GameState.spawn_id, GameState.spawn_position)
	await show_card("retry", "Try again", "")
	await fade_in()
	_busy -= 1
	Events.toast.emit("Back to the last checkpoint.")


# --- Fades and cards ---------------------------------------------------------

func fade_out(duration: float = FADE_TIME) -> void:
	await _tween_fade(1.0, duration)


func fade_in(duration: float = FADE_TIME) -> void:
	await _tween_fade(0.0, duration)


## Fades back in if a card or fade left the screen black (used between dialogue steps).
func ensure_visible() -> void:
	if _fade_rect.color.a > 0.01 and _busy == 0:
		await fade_in()


## Shows a title card on black. kind: "chapter", "timeskip" or "retry". Awaitable.
func show_card(kind: String, title: String, subtitle: String = "") -> void:
	_busy += 1
	if _fade_rect.color.a < 0.99:
		await fade_out(0.6)
	_card_title.text = title
	_card_subtitle.text = subtitle
	Events.card_shown.emit(kind, title, subtitle)
	await _tween_card_alpha(1.0, 0.8)
	await _hold_card(CARD_HOLD if kind != "retry" else 0.8)
	await _tween_card_alpha(0.0, 0.6)
	_busy -= 1


func _enter_game() -> void:
	_busy += 1
	await fade_out()
	get_tree().change_scene_to_file(GAME_SCENE)
	await game_registered
	if _show_intro_card:
		_show_intro_card = false
		await show_card("chapter", "Chapter %d" % GameState.chapter, _chapter_title(GameState.chapter))
	_busy -= 1
	_load_current_zone()


func _load_current_zone() -> void:
	_busy += 1
	game.load_zone(GameState.zone_id, GameState.spawn_id, GameState.spawn_position)
	GameState.save_checkpoint(GameState.spawn_position)
	await fade_in()
	_busy -= 1
	game.run_zone_entry_scripts()


func _chapter_title(chapter: int) -> String:
	var titles: Dictionary = DB.heroes.get("chapter_titles", {})
	return String(titles.get(str(chapter), ""))


func _hold_card(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if elapsed > 0.5 and Input.is_action_just_pressed("interact"):
			return


func _tween_fade(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", alpha, duration)
	await tween.finished


func _tween_card_alpha(alpha: float, duration: float) -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(_card_title, "modulate:a", alpha, duration)
	tween.tween_property(_card_subtitle, "modulate:a", alpha, duration)
	await tween.finished


func _make_fade_rect() -> ColorRect:
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	return rect


func _make_card_label(font_size: int, y: float) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, y)
	label.size = Vector2(960, 48)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e8dcc0"))
	label.modulate.a = 0.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
