class_name BossHealthBar
extends Control
## The boss bar at the top-centre of the HUD: the boss's name in the HUD's pixel font over a
## wide health bar. It fades in when a boss fight starts and out when the boss falls. A hit
## leaves a pale segment that drains after a moment, so big hits read. A notch marks half
## health, where bosses change phase. The victory text is its DefeatedBanner child.
##
## Bosses reach it through the static `show_boss` / `announce_defeat` / `hide_boss` (a group
## call), so a boss needs no reference to the HUD.

const GROUP := "boss_health_bar"
## Length of the bar, in game pixels.
const BAR_LENGTH := 120
const BAR_HEIGHT := 3
## Top of the name, in game pixels (below the debug banner's row).
const TOP := 12
const NAME_GAP := 2
const FADE_SECONDS := 0.5
## How fast the bar gets out of the way of a discovery card that shares the top-centre.
const MAKE_WAY_SECONDS := 0.15
## The pale "damage taken" segment waits this long, then drains at this share per second.
const DRAIN_DELAY_SECONDS := 0.4
const DRAIN_SHARE_PER_SECOND := 0.5

var _health: Health = null
var _boss_name: String = ""
var _shown_share: float = 1.0
var _drain_delay := HudMotion.new(DRAIN_DELAY_SECONDS)
## Whether the fight wants the bar up (from `track` until the boss falls or the fight resets).
var _is_wanted: bool = false
## Whether the bar is (fading) up right now: false while a discovery card holds the top-centre.
var _is_up: bool = false
var _fade: Tween = null

@onready var defeated_banner: BossDefeatedBanner = $DefeatedBanner


## Shows `boss_name` and its `health` on the HUD of `asker`'s level.
static func show_boss(asker: Node, boss_name: String, health: Health) -> void:
	asker.get_tree().call_group(GROUP, "track", boss_name, health)


## Hides the bar and announces "<NAME> DEFEATED".
static func announce_defeat(asker: Node, boss_name: String) -> void:
	asker.get_tree().call_group(GROUP, "show_defeat", boss_name)


## Fades the bar out without a victory (the fight reset after the player fell).
static func hide_boss(asker: Node) -> void:
	asker.get_tree().call_group(GROUP, "untrack")


func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(DiscoveryCard.WATCHERS_GROUP)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	self_modulate.a = 0.0


func track(boss_name: String, health: Health) -> void:
	_boss_name = boss_name.to_upper()
	_health = health
	_shown_share = _share_left()
	if not health.hit_taken.is_connected(_on_hit_taken):
		health.hit_taken.connect(_on_hit_taken)
	_is_wanted = true
	_update_fade()
	queue_redraw()


func untrack() -> void:
	_is_wanted = false
	_update_fade()
	_health = null


func show_defeat(boss_name: String) -> void:
	_is_wanted = false
	_update_fade()
	defeated_banner.announce("%s DEFEATED" % boss_name.to_upper())


## A discovery card came up or went: make way for it, or come back.
func on_discovery_card_changed() -> void:
	_update_fade()


## Fades the bar up while the fight wants it, except while a discovery card holds the
## top-centre (e.g. the first toads a boss summons): the two would overlap, so the bar makes
## way quickly and comes back once the card has gone.
func _update_fade() -> void:
	var is_card_up := DiscoveryCard.is_showing_on(self)
	var should_be_up := _is_wanted and not is_card_up
	if should_be_up == _is_up:
		return
	_is_up = should_be_up
	_fade_to(1.0 if should_be_up else 0.0, MAKE_WAY_SECONDS if is_card_up else FADE_SECONDS)


## Fades the bar (not its DefeatedBanner child: self_modulate) over `seconds` real seconds.
func _fade_to(alpha: float, seconds: float) -> void:
	if _fade != null:
		_fade.kill()
	_fade = create_tween().set_ignore_time_scale(true)
	_fade.tween_property(self, "self_modulate:a", alpha, seconds)


func _on_hit_taken(_amount: int, _is_critical: bool, _damage_type: Health.DamageType) -> void:
	_drain_delay.start()
	queue_redraw()


func _process(delta: float) -> void:
	if not _is_tracking():
		return
	if _drain_delay.advance(delta) or _shown_share <= _share_left():
		_shown_share = maxf(_shown_share, _share_left())
		return
	_shown_share = maxf(_share_left(), _shown_share - DRAIN_SHARE_PER_SECOND * delta)
	queue_redraw()


func _draw() -> void:
	if not _is_tracking():
		return
	var centre := floorf(size.x / 2.0)
	var name_left := centre - floorf(PixelFont.width_of(_boss_name) / 2.0)
	PixelFont.draw_text(self, _boss_name, Vector2(name_left, TOP), ApolloPalette.CREAM, ApolloPalette.OUTLINE)
	var bar := Rect2(centre - BAR_LENGTH / 2.0, TOP + PixelFont.GLYPH_HEIGHT + NAME_GAP + 1, BAR_LENGTH, BAR_HEIGHT)
	# Same build as the HUD's frames: drop shadow, rounded outline, then a lit top row and a
	# shaded bottom row on both the empty track and the fill, so the bar reads as a tube.
	PixelShape.draw_drop_shadow(self, bar.grow(1.0))
	PixelShape.draw_rounded_outline(self, bar.grow(1.0), ApolloPalette.OUTLINE)
	draw_rect(bar, ApolloPalette.PLUM_DARK)
	draw_rect(Rect2(bar.position + Vector2(0, BAR_HEIGHT - 1), Vector2(BAR_LENGTH, 1)), ApolloPalette.COAL_DARK)
	var damage_taken_segment := Vector2(roundf(BAR_LENGTH * _shown_share), BAR_HEIGHT)
	draw_rect(Rect2(bar.position, damage_taken_segment), ApolloPalette.CREAM)
	var filled := roundf(BAR_LENGTH * _share_left())
	draw_rect(Rect2(bar.position, Vector2(filled, BAR_HEIGHT)), ApolloPalette.RED_LIGHT)
	draw_rect(Rect2(bar.position, Vector2(filled, 1)), ApolloPalette.ORANGE)
	draw_rect(Rect2(bar.position + Vector2(0, BAR_HEIGHT - 1), Vector2(filled, 1)), ApolloPalette.RED)
	# The phase-2 notch at half health.
	draw_rect(Rect2(bar.position + Vector2(BAR_LENGTH / 2.0, -1), Vector2(1, BAR_HEIGHT + 2)), ApolloPalette.OUTLINE)


## False before a fight, and once the boss has been freed.
func _is_tracking() -> bool:
	if _health != null and not is_instance_valid(_health):
		_health = null
	return _health != null


func _share_left() -> float:
	return clampf(float(_health.current_health) / float(_health.max_health), 0.0, 1.0)
