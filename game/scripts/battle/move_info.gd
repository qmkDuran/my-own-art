class_name MoveInfo
extends Panel
## Beside the move list: the highlighted move's element, what it does, and how it matches the foe.

var _foe: Creature
var _badge: TextureRect
var _element: Label
var _power: Label
var _match: Label


func setup(rect: Rect2, foe: Creature) -> void:
	_foe = foe
	position = rect.position
	size = rect.size
	add_theme_stylebox_override("panel", UiKit.panel_style("cream"))
	_badge = TextureRect.new()
	_badge.position = Vector2(6, 6)
	add_child(_badge)
	_element = _row(Vector2(19, 2), "ink", false)
	_power = _row(Vector2(6, 16), "ink2", true)
	_match = _row(Vector2(6, 28), "ember1", true)


func _row(at: Vector2, colour: String, small: bool) -> Label:
	var l := UiKit.label("", colour, small)
	l.position = at
	add_child(l)
	return l


func show_move(id: String) -> void:
	var m: Dictionary = Db.move(id)
	var element: String = String(m["element"])
	_badge.texture = load("res://art/ui/elem_%s.png" % element)
	_element.text = Db.element_name(element)
	match String(m["kind"]):
		"attack":
			_power.text = "Power %d" % int(m["power"])
			var mult: float = Db.element_mult(element, _foe.element())
			_match.text = "Strong match" if mult > 1.0 else ("Weak match" if mult < 1.0 else "")
		"heal":
			_power.text = "Heals self"
			_match.text = ""
		"buff":
			_power.text = "Raises %s" % _stat_name(String(m["stat"]))
			_match.text = ""
		_:
			_power.text = "Lowers foe %s" % _stat_name(String(m["stat"]))
			_match.text = ""


func _stat_name(stat: String) -> String:
	return "Attack" if stat == "atk" else "Defense"
