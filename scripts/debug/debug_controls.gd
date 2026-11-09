class_name DebugControls
extends CanvasLayer
## Developer switches for testing (every debug key lives here), toggled with keys checked
## directly (no input actions, so the project settings stay untouched). One per level scene.
##
## F2: enemies passive. Toads sit still (no hops, no tongue) and Wardens stand still
## (no summons, no shove, no slam). They can still be hit and killed.
## F3: DEBUG ONLY, +5 Ember Tree skill points, to try out builds without levelling.
## F4: cycles Emberoo's Awakening stage (0, 1, 2, then back to 0) to see each look at once;
## stepping up plays the short awakening moment too.
## F5: save now (a "SAVED" toast confirms it). F6: Emberoo falls at once (to test death and respawn).
## F7: DEBUG ONLY, a random tier-2 hacked chip and 50 scrap (see DebugChipGrant).
## F9: delete the save and restart the zone fresh.
## While enemies are passive, a banner at the top centre of the screen lists the keys.

const PASSIVE_TOGGLE_KEY := KEY_F2
const GRANT_POINTS_KEY := KEY_F3
const AWAKENING_KEY := KEY_F4
const SAVE_KEY := KEY_F5
const FALL_KEY := KEY_F6
const CHIP_KEY := KEY_F7
const DELETE_SAVE_KEY := KEY_F9
## Skill points F3 grants (debug only).
const DEBUG_SKILL_POINTS := 5
## "%d" is DEBUG_SKILL_POINTS.
const BANNER_FORMAT := "ENEMIES PAUSED (F2)   F3 +%d POINTS   F4 AWAKEN   F5 SAVE   F6 FALL   F7 CHIP   F9 WIPE SAVE"
## Top edge of the banner text, in screen pixels.
const BANNER_TOP := 3

## Read by the enemies every frame. A static var, so every enemy can read it without a reference.
static var enemies_passive: bool = false

## Whether enemies start paused in this level: on in the test arena (for tuning against the
## training dummy), off in real zones.
@export var start_with_enemies_paused: bool = false
## Whether this level loads and writes the real save: off in the test arena, so tuning
## there never touches the player's progress (it starts fresh instead).
@export var uses_save_file: bool = true

var _save_toast := SaveToast.new()

@onready var banner: Node2D = $Banner


## Runs before any node in the level reads progress in its _ready.
func _enter_tree() -> void:
	if not uses_save_file:
		SaveGame.disable_for_session()


func _ready() -> void:
	enemies_passive = start_with_enemies_paused
	banner.draw.connect(_draw_banner)
	_refresh_banner()
	add_child(_save_toast)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var action := _action_for_key(key.keycode)
	if action.is_valid():
		action.call()
		get_viewport().set_input_as_handled()


## What each debug key does (an empty Callable for any other key).
func _action_for_key(keycode: Key) -> Callable:
	match keycode:
		PASSIVE_TOGGLE_KEY:
			return _toggle_enemies_passive
		GRANT_POINTS_KEY:
			return Progression.add_skill_points.bind(DEBUG_SKILL_POINTS)
		AWAKENING_KEY:
			return _cycle_awakening
		SAVE_KEY:
			return _save_now
		FALL_KEY:
			return _make_player_fall
		CHIP_KEY:
			return DebugChipGrant.grant
		DELETE_SAVE_KEY:
			return SaveGame.delete_save_and_restart
	return Callable()


func _toggle_enemies_passive() -> void:
	enemies_passive = not enemies_passive
	_refresh_banner()


func _save_now() -> void:
	if SaveGame.save_now():
		_save_toast.show_toast()


## The next Awakening stage, wrapping from the last back to none.
func _cycle_awakening() -> void:
	var next_stage := (Awakening.stage + 1) % (AwakeningStage.LAST + 1)
	Awakening.set_stage(next_stage, next_stage > Awakening.stage)


## Takes all of Emberoo's health at once, past a dodge's or the entrance hop's invulnerability.
func _make_player_fall() -> void:
	var health := PlayerFinder.find_component(self, Health.NODE_NAME) as Health
	if health == null or health.is_dead():
		return
	health.is_invulnerable = false
	health.take_tick_damage(health.current_health, Health.DamageType.DIRECT)


func _refresh_banner() -> void:
	banner.visible = enemies_passive
	banner.queue_redraw()


func _draw_banner() -> void:
	var banner_text := BANNER_FORMAT % DEBUG_SKILL_POINTS
	var screen_width := get_viewport().get_visible_rect().size.x
	var left := floorf((screen_width - PixelFont.width_of(banner_text)) / 2.0)
	PixelFont.draw_text(banner, banner_text, Vector2(left, BANNER_TOP), ApolloPalette.GOLD, ApolloPalette.OUTLINE)
