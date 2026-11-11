class_name CreatureCard
extends Panel
## A battle info card: element badge, name, level and HP bar; yours adds HP numbers and an XP bar, a wild one
## adds the Trust meter (five hearts) and its current mood.

const W: int = 128
const H_ALLY: int = 38
const H_FOE: int = 40
const HEARTS: int = 5
const HEART_STEP: int = 10
const BAR_W: int = 96

var battler: Battler
var ally: bool = false
var hp_bar: Meter
var xp_bar: Meter
var _name: Label
var _level: Label
var _numbers: Label
var _hearts: Array[TextureRect] = []
var _mood_icon: TextureRect
var _mood: Label
var _badge: TextureRect
var _status: Label
var _full: Texture2D = preload("res://art/ui/heart_full.png")
var _half: Texture2D = preload("res://art/ui/heart_half.png")
var _empty: Texture2D = preload("res://art/ui/heart_empty.png")


func setup(is_ally: bool) -> CreatureCard:
	ally = is_ally
	add_theme_stylebox_override("panel", UiKit.panel_style())
	size = Vector2(W, H_ALLY if ally else H_FOE)
	_badge = _icon(Vector2(5, 5))
	_name = _text(Vector2(17, 1), "ink")
	_level = _text(Vector2(W - 30, 3), "dusk", true)
	_text(Vector2(5, 15), "ember1", true).text = "HP"
	hp_bar = Meter.new().setup(BAR_W if not ally else BAR_W - 30, 5, "leaf3", true)
	hp_bar.position = Vector2(22, 17)
	add_child(hp_bar)
	if ally:
		_build_ally_rows()
	else:
		_build_trust_row()
	_status = _text(Vector2(78, 25) if ally else Vector2(5, H_FOE - 1), "ink", true)
	return self


func _build_ally_rows() -> void:
	_numbers = _text(Vector2(W - 34, 14), "ink2", true)
	_text(Vector2(5, 27), "water2", true).text = "XP"
	xp_bar = Meter.new().setup(52, 4, "water3")
	xp_bar.position = Vector2(22, 30)
	add_child(xp_bar)


func _build_trust_row() -> void:
	for i: int in HEARTS:
		var h: TextureRect = _icon(Vector2(5 + i * HEART_STEP, 27))
		_hearts.append(h)
	_mood_icon = _icon(Vector2(60, 25))
	_mood = _text(Vector2(74, 23), "ink2", true)


func _icon(at: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.position = at
	add_child(t)
	return t


func _text(at: Vector2, colour: String, small: bool = false) -> Label:
	var l := UiKit.label("", colour, small)
	l.position = at
	add_child(l)
	return l


func show_battler(b: Battler) -> void:
	battler = b
	var c: Creature = b.creature
	_badge.texture = load("res://art/ui/elem_%s.png" % c.element())
	_name.text = c.display_name()
	_level.text = "Lv%d" % c.level
	hp_bar.set_fraction(b.hp_ratio())
	refresh_text()
	if ally:
		xp_bar.set_fraction(float(c.xp) / Growth.xp_to_next(c.level))
	_set_trust_row_visible(b.wild)
	show_status()


## The condition tag (Singed, Drowsy, Rattled); the foe card grows a row for it.
func show_status() -> void:
	var id: String = battler.status
	_status.visible = id != ""
	var base_h: float = H_FOE if battler.wild else H_ALLY - 12
	if id == "":
		if not ally:
			size.y = base_h
		return
	_status.text = String(StatusRules.data(id)["name"]).to_upper()
	_status.add_theme_color_override("font_color", UiKit.c(String(StatusRules.data(id)["colour"])))
	if not ally:
		_status.position.y = base_h - 3
		size.y = base_h + 9


func _set_trust_row_visible(on: bool) -> void:
	for h: TextureRect in _hearts:
		h.visible = on
	if _mood != null:
		_mood.visible = on
		_mood_icon.visible = on
	if not ally:
		size.y = H_FOE if on else H_ALLY - 12


func refresh_text() -> void:
	if ally:
		_numbers.text = "%d/%d" % [battler.creature.hp, battler.creature.max_hp()]


func update_hp() -> void:
	await hp_bar.animate_to(battler.hp_ratio())
	refresh_text()


func update_trust() -> void:
	var filled: int = int(round(float(battler.trust) / TrustRules.FULL * HEARTS * 2))
	for i: int in HEARTS:
		var left: int = filled - i * 2
		_hearts[i].texture = _full if left >= 2 else (_half if left == 1 else _empty)
	_mood_icon.texture = load("res://art/ui/mood_%s.png" % battler.mood)
	_mood.text = battler.mood.capitalize()


func update_xp() -> void:
	_level.text = "Lv%d" % battler.creature.level
	await xp_bar.animate_to(float(battler.creature.xp) / Growth.xp_to_next(battler.creature.level))
