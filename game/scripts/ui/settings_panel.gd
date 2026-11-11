class_name SettingsPanel
extends ScreenPanel
## Settings: music and sound volume and text speed. Accept (or a click) steps a value; changes save at once.

const ROWS: PackedStringArray = ["Music", "Sounds", "Text speed", "Back"]
const VALUE_X: int = 120


func run() -> void:
	set_title("Settings")
	var list := MenuList.new()
	content.add_child(list)
	list.setup(ROWS, 1, VALUE_X - 8)
	var values: Array[Label] = []
	for i: int in ROWS.size() - 1:
		values.append(add_label("", Vector2(VALUE_X, i * MenuList.ROW_H - 1), "ember1"))
	_show(values)
	while true:
		var i: int = await list.pick()
		if i < 0 or i == ROWS.size() - 1:
			return
		_step(i)
		Settings.save_settings()
		Audio.apply_volumes()
		_show(values)


func _step(row: int) -> void:
	match row:
		0:
			Settings.music = (Settings.music + 1) % (Settings.MAX_VOLUME + 1)
		1:
			Settings.sounds = (Settings.sounds + 1) % (Settings.MAX_VOLUME + 1)
		2:
			Settings.next_speed()


func _show(values: Array[Label]) -> void:
	values[0].text = _bar(Settings.music)
	values[1].text = _bar(Settings.sounds)
	values[2].text = Settings.text_speed


func _bar(level: int) -> String:
	return "%s %d" % ["|".repeat(level) + ".".repeat(Settings.MAX_VOLUME - level), level]
