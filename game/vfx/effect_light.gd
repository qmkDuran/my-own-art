class_name EffectLight
extends OmniLight3D
## A short-lived effect light (a bolt's glow, an impact's pop) that holds a slot in the VfxQuota while it shines:
## no slot, no light. It can fade out over a time and then free itself.

var _quota: VfxQuota
var _has_slot: bool = false


## A light in a colour; returns null when the quota is full (the effect simply goes without).
static func make(quota: VfxQuota, colour: Color, energy: float, reach: float) -> EffectLight:
	if not quota.take_light():
		return null
	var light := EffectLight.new()
	light._quota = quota
	light._has_slot = true
	light.light_color = colour
	light.light_energy = energy
	light.omni_range = reach
	light.shadow_enabled = false
	return light


func fade_out(seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "light_energy", 0.0, seconds)
	tween.tween_callback(queue_free)


func _exit_tree() -> void:
	if _has_slot:
		_has_slot = false
		_quota.give_light()
