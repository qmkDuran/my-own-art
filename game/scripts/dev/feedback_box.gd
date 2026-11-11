class_name FeedbackBox
extends CanvasLayer
## F8: the game pauses and a one-line box opens. Enter saves playtest/notes/<time>.md (the note, zone, position,
## level, build, life and Light, the last 30 s of combat) with a screenshot beside it; Esc cancels.

const LAYER: int = 50
const BOX := Vector2(560, 34)

var g: Game
var _edit: LineEdit
var _shot: Image


func setup(game: Game) -> void:
	g = game
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_edit = LineEdit.new()
	_edit.placeholder_text = "What did you notice? (Enter saves, Esc cancels)"
	_edit.custom_minimum_size = BOX
	_edit.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_edit.position = Vector2(-BOX.x / 2.0, 80.0)
	_edit.visible = false
	_edit.text_submitted.connect(_save)
	add_child(_edit)


func open() -> void:
	_shot = get_viewport().get_texture().get_image()        # the moment as it was, before the box covers it
	get_tree().paused = true
	_edit.text = ""
	_edit.visible = true
	_edit.grab_focus()


func is_open() -> bool:
	return _edit.visible


func close() -> void:
	_edit.visible = false
	get_tree().paused = false


func _save(text: String) -> void:
	var name: String = Dev.stamp()
	var dir: String = Dev.playtest_dir("notes")
	if _shot != null:                                      # headless runs have no picture
		_shot.save_png(dir.path_join(name + ".png"))
	var f := FileAccess.open(dir.path_join(name + ".md"), FileAccess.WRITE)
	if f != null:
		f.store_string(_report(text, name))
	g.hud.notice("Note saved: playtest/notes/%s.md" % name)
	close()


func _report(text: String, name: String) -> String:
	var p: Player = g.player
	var slots: PackedStringArray = []
	for k: String in p.prog.slots:
		slots.append("%s=%s" % [k, p.prog.slots[k]])
	var lines: PackedStringArray = ["# %s" % text, "", "![screenshot](%s.png)" % name, "",
		"- zone: %s at %s" % [g.zone_id, p.global_position.round()],
		"- level %d, mastery %s, skills %s" % [p.prog.level, p.prog.mastery if p.prog.mastery != "" else "none", ", ".join(slots)],
		"- specialised: %s" % ", ".join(PackedStringArray(p.prog.specialised)),
		"- life %d / %d, Light %.0f (%s), tonics %d" % [p.life, p.stats.max_life(), p.light.value, p.light.state(), p.tonics],
		"- quest: %s" % (Session.campaign.active()[0] if not Session.campaign.active().is_empty() else "none"),
		"", "## Last 30 s of combat", "", "```"]
	lines.append_array(CombatLog.recent())
	lines.append("```")
	return "\n".join(lines) + "\n"
