class_name PausePanel
extends GamePanel
## Esc menu: resume, the feel settings (screen shake, damage numbers, brightness: click the left half to lower it,
## the right half to raise it), and save & return to the title.

const BTN := Vector2(236, 22)
const GAP: float = 6.0
const PAD: float = 14.0
const FOOTER: float = 26.0
const ITEMS: Array[String] = ["resume", "help", "guide", "shake", "numbers", "brightness", "graphics", "quit"]
const BRIGHT_STEP: float = 0.1


## The panel is sized to hold every item and the footer line, so nothing ever spills out of it.
static func panel_size_for() -> Vector2:
	return Vector2(BTN.x + PAD * 2.0 + 60.0, CONTENT_Y + PAD + ITEMS.size() * (BTN.y + GAP) + FOOTER)


func item_rect(i: int) -> Rect2:
	return Rect2(roundf((size.x - BTN.x) / 2.0), CONTENT_Y + PAD + i * (BTN.y + GAP), BTN.x, BTN.y)


## Everything drawn inside the panel (the UI check makes sure it all fits).
func layout_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for i: int in ITEMS.size():
		out.append(item_rect(i))
	out.append(Rect2(PAD, size.y - FOOTER + 6.0, size.x - PAD * 2.0, 12.0))
	return out


func _label(id: String) -> String:
	match id:
		"resume": return "Resume"
		"help": return "Help and controls (H)"
		"guide": return "Objective pointer: %s" % ("on" if bool(GameData.setting("guide", false)) else "off")
		"shake": return "Screen shake: %s" % ("on" if float(GameData.setting("screen_shake", 1.0)) > 0.0 else "off")
		"numbers": return "Damage numbers: %s" % ("on" if FloatText.enabled else "off")
		"graphics": return "Graphics: %s (next zone)" % String(GameData.setting("graphics", "medium")).capitalize()
		"brightness": return "<   Brightness %d%%   >" % roundi(Atmosphere.brightness() * 100.0)
	return "Save and quit to title"


func _content() -> void:
	for i: int in ITEMS.size():
		button(item_rect(i), _label(ITEMS[i]))
	var foot: Rect2 = layout_rects().back()
	UiDraw.text(self, foot.position + Vector2(0, 9), "All art and sound made from code. Fonts: OFL.", UiDraw.DIM,
		UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, foot.size.x)


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
		"help":
			g.ui.set_paused(false)
			g.ui.open(g.ui.help)
		"guide":
			GameData.settings["guide"] = not bool(GameData.setting("guide", false))
		"shake":
			GameData.settings["screen_shake"] = 0.0 if float(GameData.setting("screen_shake", 1.0)) > 0.0 else 1.0
		"numbers":
			FloatText.enabled = not FloatText.enabled
			GameData.settings["damage_numbers"] = FloatText.enabled
		"graphics":
			var i: int = Atmosphere.QUALITY_ORDER.find(String(GameData.setting("graphics", "medium")))
			GameData.settings["graphics"] = Atmosphere.QUALITY_ORDER[(i + 1) % Atmosphere.QUALITY_ORDER.size()]
		"quit":
			if SaveGame.enabled():
				SaveGame.write(g)
			g.ui.set_paused(false)
			get_tree().change_scene_to_file("res://scenes/title.tscn")


func _brighten(step: float) -> void:
	GameData.settings["brightness"] = clampf(Atmosphere.brightness() + step, Atmosphere.BRIGHT_MIN, Atmosphere.BRIGHT_MAX)
	g.darkness = Atmosphere.ambient(GameData.biome)
	g.dark.color = g.darkness
