class_name InputKeyLabel
extends RefCounted
## The one-glyph key name the HUD shows for an input action (Q for skill_1, F for trainer_aid),
## read from the InputMap so that rebinding a key updates the HUD by itself.
##
## Uses the first keyboard key bound to the action, as labelled on the player's keyboard layout.
## A longer key name ("Space", "Tab") is shown by its first character; a key PixelFont cannot
## draw shows nothing.


static func for_action(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event in InputMap.action_get_events(action):
		var key_event := event as InputEventKey
		if key_event != null:
			return _one_glyph(_key_name(key_event))
	return ""


## The key's name; a physical key is named as labelled on the current keyboard layout
## (where the display server knows the layout; the headless one doesn't).
static func _key_name(key_event: InputEventKey) -> String:
	var keycode := key_event.keycode
	if keycode == KEY_NONE:
		keycode = key_event.physical_keycode
		if keycode != KEY_NONE and DisplayServer.get_name() != "headless":
			var layout_keycode := DisplayServer.keyboard_get_label_from_physical(keycode)
			keycode = layout_keycode if layout_keycode != KEY_NONE else keycode
	return OS.get_keycode_string(keycode)


static func _one_glyph(key_name: String) -> String:
	if key_name.is_empty():
		return ""
	var first := key_name.substr(0, 1).to_upper()
	return first if PixelFont.GLYPHS.has(first) else ""
