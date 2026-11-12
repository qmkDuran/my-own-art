class_name RustleCue
extends Control
## Fairness cue: when the bot is close, moving and unseen, three amber chevrons on a ring around the crosshair point
## toward the sound ("rustle"), so you are never ambushed without warning.

const RING_RADIUS: float = 140.0
const CHEVRONS: int = 3
const CHEVRON_GAP: float = 14.0
const CHEVRON_SIZE: float = 12.0
const LINE_WIDTH: float = 3.0
const LABEL_WIDTH: float = 120.0
const PULSE_RATE: float = 6.0
const PULSE_FLOOR: float = 0.55

var _sight: PlayerSight
var _rig: CameraRig
var _clock: float = 0.0


func setup(sight: PlayerSight, rig: CameraRig) -> void:
	_sight = sight
	_rig = rig
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	if not _sight.rustling:
		return
	var offset: Vector3 = _sight.rustle_from - _rig.global_position
	var local: Vector3 = offset.rotated(Vector3.UP, -_rig.yaw)
	var direction: Vector2 = Vector2(local.x, local.z).normalized()
	var wave: float = sin(_clock * PULSE_RATE)
	var pulse: float = lerpf(PULSE_FLOOR, 1.0, 0.5 + 0.5 * wave)
	var color := Color(HudStyle.HEARD_COLOR, pulse)
	var centre: Vector2 = size * 0.5
	for k: int in CHEVRONS:
		var tip: Vector2 = centre + direction * (RING_RADIUS + k * CHEVRON_GAP)
		var back: Vector2 = -direction * CHEVRON_SIZE
		draw_polyline(PackedVector2Array([tip + back + back.orthogonal(), tip, tip + back - back.orthogonal()]),
				color, LINE_WIDTH)
	var label_at: Vector2 = centre + direction * (RING_RADIUS - CHEVRON_GAP * 2.0)
	HudStyle.text(self, label_at + Vector2(-LABEL_WIDTH * 0.5, 0), "rustle", HudStyle.FONT_SMALL, color,
			HORIZONTAL_ALIGNMENT_CENTER, LABEL_WIDTH)
