class_name ScreenPanel
extends Control
## Base for full-screen menus (team, summary, journal, bag, shop): a framed sheet with a title tab and a
## content area that adapts to the screen size. Subclasses fill `content` and implement `run()`.

const MARGIN: int = 4
const TITLE_H: int = 16

var frame: Panel
var content: Control
var _title: Label
var _title_tab: Panel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view: Vector2 = get_viewport_rect().size
	var backing := ColorRect.new()
	backing.color = UiKit.c("ink2")
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backing)
	frame = UiKit.panel(Rect2(MARGIN, MARGIN + TITLE_H, view.x - MARGIN * 2, view.y - MARGIN * 2 - TITLE_H))
	add_child(frame)
	_title_tab = UiKit.panel(Rect2(MARGIN + 6, MARGIN, 80, TITLE_H), "ink2", "ink")
	add_child(_title_tab)
	_title = UiKit.label("", "cream")
	_title.position = Vector2(6, 1)
	_title_tab.add_child(_title)
	content = Control.new()
	content.position = Vector2(6, 6)
	content.size = frame.size - Vector2(12, 12)
	frame.add_child(content)


func set_title(text: String) -> void:
	_title.text = text
	_title_tab.size.x = UiKit.text_width(text) + 12


func add_label(text: String, at: Vector2, colour: String = "ink", small: bool = false) -> Label:
	var l := UiKit.label(text, colour, small)
	l.position = at
	content.add_child(l)
	return l


func add_icon(path: String, at: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.position = at
	content.add_child(t)
	return t


func clear_content() -> void:
	for child: Node in content.get_children():
		child.queue_free()


## Waits for cancel or accept (read-only pages).
func wait_close() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("accept"):
			Audio.sfx("cancel")
			return
