class_name PartyCard
extends Panel
## One creature in the team grid: icon, name, level, element, HP bar and numbers. Highlighted when selected.

const SIZE: Vector2 = Vector2(148, 42)

var creature: Creature


func setup(c: Creature) -> PartyCard:
	creature = c
	size = SIZE
	set_selected(false)
	var icon := TextureRect.new()
	icon.texture = UiKit.creature_tex(c.species_id, "icon")
	icon.position = Vector2(4, 8)
	add_child(icon)
	_label(c.display_name(), Vector2(32, 1), "ink")
	_label("Lv%d" % c.level, Vector2(SIZE.x - 30, 4), "dusk", true)
	var badge := TextureRect.new()
	badge.texture = load("res://art/ui/elem_%s.png" % c.element())
	badge.position = Vector2(SIZE.x - 44, 5)
	add_child(badge)
	var hp := Meter.new().setup(80, 5, "leaf3", true)
	hp.position = Vector2(32, 17)
	hp.set_fraction(float(c.hp) / c.max_hp())
	add_child(hp)
	_label("%d/%d" % [c.hp, c.max_hp()], Vector2(32, 25), "ink2", true)
	if c.is_fainted():
		_label("RESTING", Vector2(90, 25), "ember1", true)
	return self


func _label(text: String, at: Vector2, colour: String, small: bool = false) -> void:
	var l := UiKit.label(text, colour, small)
	l.position = at
	add_child(l)


func set_selected(on: bool) -> void:
	add_theme_stylebox_override("panel", UiKit.panel_style("cream" if on else "paper", "ember2" if on else "ink",
		2 if on else 1))
