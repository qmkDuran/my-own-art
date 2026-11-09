class_name LinkMeterBar
extends Control
## The team's Link meter on the HUD, next to the team cards: a "LINK" label over a bar in
## three segments that fills from hits, reactions and Signal Skills. Full, it pulses gold
## and says "FINISHER": the next Signal Skill is a Link Finisher.
## Finds the LinkMeter by its group, so levels without one show nothing.

const LABEL := "LINK"
const FULL_LABEL := "FINISHER"
const BAR_TOP := 7
const BAR_SIZE := Vector2(34, 3)
const SEGMENTS := 3
const PULSE_SPEED := 12.0

var _meter: LinkMeter


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if not is_instance_valid(_meter):
		_meter = get_tree().get_first_node_in_group(LinkMeter.GROUP) as LinkMeter
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(_meter):
		return
	var is_full := _meter.is_full()
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * PULSE_SPEED)
	var label_color := ApolloPalette.GOLD.lerp(ApolloPalette.WHITE, pulse) if is_full else ApolloPalette.CREAM
	PixelFont.draw_text(self, FULL_LABEL if is_full else LABEL, Vector2.ZERO, label_color, ApolloPalette.OUTLINE)
	var bar := Rect2(Vector2(0, BAR_TOP), BAR_SIZE)
	draw_rect(bar.grow(1), ApolloPalette.OUTLINE)
	draw_rect(bar, ApolloPalette.COAL)
	var fill_color := label_color if is_full else ApolloPalette.SKY_LIGHT
	draw_rect(Rect2(bar.position, Vector2(roundf(BAR_SIZE.x * _meter.share()), BAR_SIZE.y)), fill_color)
	for segment in range(1, SEGMENTS):
		var x := roundf(BAR_SIZE.x * segment / SEGMENTS)
		draw_line(Vector2(x, BAR_TOP), Vector2(x, BAR_TOP + BAR_SIZE.y), ApolloPalette.OUTLINE, 1.0)
