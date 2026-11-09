class_name AwakeningAnnouncement
extends Control
## The HUD's half of the awakening moment (see AwakeningMoment): at the flare the screen
## flashes briefly and a banner says e.g. "PYROO EVOLVED INTO EMBEROO" at the top-centre.

const BANNER_FORMAT := "%s EVOLVED INTO %s"
## How strong the flash starts (its alpha) and how long it takes to fade, in seconds.
const FLASH_ALPHA := 0.55
const FLASH_FADE_SECONDS := 0.35

var _flash := ColorRect.new()
var _banner := BossDefeatedBanner.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(ApolloPalette.WHITE, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)
	_banner.text_color = ApolloPalette.SKY_LIGHT
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_banner)
	Awakening.awakened.connect(_on_awakened)


func _on_awakened(stage: int) -> void:
	var timeline := create_tween()
	timeline.tween_interval(AwakeningMoment.FLARE_DELAY)
	timeline.tween_callback(_show.bind(stage))


func _show(stage: int) -> void:
	_flash.color.a = FLASH_ALPHA
	create_tween().tween_property(_flash, "color:a", 0.0, FLASH_FADE_SECONDS)
	_banner.announce(banner_text(stage))


static func banner_text(stage: int) -> String:
	var before := AwakeningStage.hero_name(stage - 1).to_upper()
	return BANNER_FORMAT % [before, AwakeningStage.hero_name(stage).to_upper()]
