class_name JournalPanel
extends ScreenPanel
## The field journal: every species of the Vale, seen and befriended marks, and for a befriended one its
## portrait, element and a note about how it lives.

const LIST_W: int = 112
const PAGE_X: int = 118

var _ids: PackedStringArray = []
var _page: Control


func run() -> void:
	set_title("Field Journal")
	_ids = PackedStringArray(Db.species.keys())
	var names: PackedStringArray = []
	for i: int in _ids.size():
		names.append("%02d %s" % [i + 1, _name_for(_ids[i])])
	var list := MenuList.new()
	content.add_child(list)
	list.max_rows = int((content.size.y - 16) / MenuList.ROW_H)
	list.setup(names, 1, LIST_W)
	list.position = Vector2(0, 14)
	add_label("Seen %d  Friends %d" % [Game.journal.seen.size(), Game.journal.befriended_count()], Vector2(0, 0), "leaf1", true)
	list.index_changed.connect(_show_page)
	_show_page(0)
	await list.pick()


func _name_for(id: String) -> String:
	return "-----" if Game.journal.status(id) == "unknown" else String(Db.species[id]["name"])


func _show_page(i: int) -> void:
	if _page != null:
		_page.queue_free()
	_page = Control.new()
	_page.position = Vector2(PAGE_X, 0)
	content.add_child(_page)
	var id: String = _ids[i]
	var status: String = Game.journal.status(id)
	_page.add_child(UiKit.panel(Rect2(0, 0, 88, 88), "cream", "ink"))
	if status == "unknown":
		_text("No sightings yet.", Vector2(0, 92), "dusk")
		return
	var art := TextureRect.new()
	art.texture = UiKit.creature_tex(id, "front")
	art.position = Vector2(4, 4)
	_page.add_child(art)
	_text(String(Db.species[id]["name"]), Vector2(94, -2), "ink")
	_text(Db.element_name(String(Db.species[id]["element"])), Vector2(94, 12), "ink2", true)
	_text("FRIEND" if status == "befriended" else "SEEN", Vector2(94, 24), "rose1" if status == "befriended" else "dusk", true)
	var note: String = String(Db.species[id]["journal"]) if status == "befriended" else "Seen in the wild. Befriend one to learn more."
	var l := UiKit.wrapped(note, content.size.x - PAGE_X)
	l.position = Vector2(0, 92)
	_page.add_child(l)


func _text(t: String, at: Vector2, colour: String, small: bool = false) -> Label:
	var l := UiKit.label(t, colour, small)
	l.position = at
	_page.add_child(l)
	return l
