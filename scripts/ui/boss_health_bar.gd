class_name BossHealthBar
extends Control
## The boss bar at the top-centre of the HUD: the boss's name in the HUD's pixel font over a
## wide health bar. It fades in when a boss fight starts and out when the boss falls. A hit
## leaves a pale segment that drains after a moment, so big hits read. A notch marks half
## health, where bosses change phase. The victory text is its DefeatedBanner child.
##
## Bosses reach it through the static `show_boss` / `announce_defeat` (a group call), so a
## boss needs no reference to the HUD.

const GROUP := "boss_health_bar"
## Length of the bar, in game pixels.
const BAR_LENGTH := 120
const BAR_HEIGHT := 3
## Top of the name, in game pixels (below the debug banner's row).
const TOP := 12
const NAME_GAP := 2
const FADE_SECONDS := 0.5
## If a discovery card has just come up (the boss's own), the bar waits until it has gone.
const DISCOVERY_CARD_SECONDS := 3.1
## The pale "damage taken" segment waits this long, then drains at this share per second.
const DRAIN_DELAY_SECONDS := 0.4
const DRAIN_SHARE_PER_SECOND := 0.5

var _health: Health = null
var _boss_name: String = ""
var _shown_share: float = 1.0
var _drain_delay := HudMotion.new(DRAIN_DELAY_SECONDS)
var _last_discovery_msec: int = -100000
var _fade: Tween = null

@onready var defeated_banner: BossDefeatedBanner = $DefeatedBanner


## Shows `boss_name` and its `health` on the HUD of `asker`'s level.
static func show_boss(asker: Node, boss_name: String, health: Health) -> void:
	asker.get_tree().call_group(GROUP, "track", boss_name, health)


## Hides the bar and announces "<NAME> DEFEATED".
static func announce_defeat(asker: Node, boss_name: String) -> void:
	asker.get_tree().call_group(GROUP, "show_defeat", boss_name)


func _ready() -> void:
	add_to_group(GROUP)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	self_modulate.a = 0.0
	CreatureLog.discovered.connect(_on_discovered)


func track(boss_name: String, health: Health) -> void:
	_boss_name = boss_name.to_upper()
	_health = health
	_shown_share = _share_left()
	health.hit_taken.connect(_on_hit_taken)
	_fade_in_when_card_gone()
	queue_redraw()


func show_defeat(boss_name: String) -> void:
	_fade_to(0.0, 0.0)
	defeated_banner.announce("%s DEFEATED" % boss_name.to_upper())


## A discovery card shares the top-centre (e.g. the first toads he summons): the bar makes
## way while it shows.
func _on_discovered(_info: Dictionary) -> void:
	_last_discovery_msec = Time.get_ticks_msec()
	if _is_tracking() and not _health.is_dead():
		self_modulate.a = 0.0
		_fade_in_when_card_gone()


func _fade_in_when_card_gone() -> void:
	var seconds_since_card := (Time.get_ticks_msec() - _last_discovery_msec) / 1000.0
	_fade_to(1.0, maxf(0.0, DISCOVERY_CARD_SECONDS - seconds_since_card))


## Fades the bar (not its DefeatedBanner child: self_modulate) after `wait` real seconds.
func _fade_to(alpha: float, wait: float) -> void:
	if _fade != null:
		_fade.kill()
	_fade = create_tween().set_ignore_time_scale(true)
	_fade.tween_interval(wait)
	_fade.tween_property(self, "self_modulate:a", alpha, FADE_SECONDS)


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
	draw_rect(bar.grow(1.0), ApolloPalette.OUTLINE)
	draw_rect(bar, ApolloPalette.PLUM_DARK)
	draw_rect(Rect2(bar.position, Vector2(roundf(BAR_LENGTH * _shown_share), BAR_HEIGHT)), ApolloPalette.CREAM)
	draw_rect(Rect2(bar.position, Vector2(roundf(BAR_LENGTH * _share_left()), BAR_HEIGHT)), ApolloPalette.RED_LIGHT)
	draw_rect(Rect2(bar.position, Vector2(roundf(BAR_LENGTH * _share_left()), 1)), ApolloPalette.ORANGE)
	# The phase-2 notch at half health.
	draw_rect(Rect2(bar.position + Vector2(BAR_LENGTH / 2.0, -1), Vector2(1, BAR_HEIGHT + 2)), ApolloPalette.OUTLINE)


## False before a fight, and once the boss has been freed.
func _is_tracking() -> bool:
	if _health != null and not is_instance_valid(_health):
		_health = null
	return _health != null


func _share_left() -> float:
	return clampf(float(_health.current_health) / float(_health.max_health), 0.0, 1.0)
