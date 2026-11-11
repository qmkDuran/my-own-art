class_name PausePanel
extends GamePanel
## Esc menu: resume, the feel settings (screen shake, damage numbers, brightness: click the left half to lower it,
## the right half to raise it), and save & return to the title.

const BTN := Vector2(200, 24)
const ITEMS: Array[String] = ["resume", "shake", "numbers", "brightness", "quit"]
const BRIGHT_STEP: float = 0.1


func item_rect(i: int) -> Rect2:
	return Rect2(roundf((size.x - BTN.x) / 2.0), CONTENT_Y + 16.0 + i * (BTN.y + 8.0), BTN.x, BTN.y)


func _label(id: String) -> String:
	match id:
		"resume": return "Resume"
		"shake": return "Screen shake: %s" % ("on" if float(GameData.setting("screen_shake", 1.0)) > 0.0 else "off")
		"numbers": return "Damage numbers: %s" % ("on" if FloatText.enabled else "off")
		"brightness": return "<   Brightness %d%%   >" % roundi(Atmosphere.brightness() * 100.0)
	return "Save and quit to title"


func _content() -> void:
	for i: int in ITEMS.size():
		button(item_rect(i), _label(ITEMS[i]))
	UiDraw.text(self, Vector2(0, size.y - 10.0), "All art, sound and music in LANTERNFALL are made from code. Fonts: OFL.", UiDraw.DIM,
		UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, size.x)


func _click(at: Vector2, _button: int) -> void:
	for i: int in ITEMS.size():
		if item_rect(i).has_point(at):
			Audio.sfx("ui_click", -8.0)
			if ITEMS[i] == "brightness":
				_brighten(BRIGHT_STEP if at.x > item_rect(i).get_center().x else -BRIGHT_STEP)
			else:
				_do(ITEMS[i])


func _do(id: String) -> void:
	match id:
		"resume":
			g.ui.set_paused(false)
		"shake":
			GameData.settings["screen_shake"] = 0.0 if float(GameData.setting("screen_shake", 1.0)) > 0.0 else 1.0
		"numbers":
			FloatText.enabled = not FloatText.enabled
			GameData.settings["damage_numbers"] = FloatText.enabled
		"quit":
			if SaveGame.enabled():
				SaveGame.write(g)
			g.ui.set_paused(false)
			get_tree().change_scene_to_file("res://scenes/title.tscn")


func _brighten(step: float) -> void:
	GameData.settings["brightness"] = clampf(Atmosphere.brightness() + step, Atmosphere.BRIGHT_MIN, Atmosphere.BRIGHT_MAX)
	g.darkness = Atmosphere.ambient(GameData.biome)
	g.dark.color = g.darkness
