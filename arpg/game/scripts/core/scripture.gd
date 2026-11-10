class_name Scripture
extends RefCounted
## All Scripture shown in the game comes from res://data/verses.json (NIV, one place; checked against the source by
## tools/check_verses.py). Scene data refers to verses by key: "{key}" -> "text  ref", "{key|block}" -> "text\nref".

const PATH: String = "res://data/verses.json"
const OMIT: String = "..."
const BREAK: String = "\n"

static var _data: Dictionary = {}
static var _token: RegEx


static func _load() -> void:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_token = RegEx.create_from_string("\\{([a-z0-9_]+)(\\|block)?\\}")


## The verse text: exact fragments joined by spaces, with "..." for deliberate omissions and line breaks.
static func text(key: String) -> String:
	_load()
	var e: Dictionary = _data["verses"][key]
	var out: String = ""
	for p: String in e["parts"]:
		if p == BREAK:
			out = out.strip_edges(false, true) + BREAK
		elif out == "" or out.ends_with(BREAK):
			out += p
		else:
			out += " " + p
	return out


static func ref(key: String) -> String:
	_load()
	return _data["verses"][key]["ref"]


static func caption(key: String) -> String:
	return text(key) + "  " + ref(key)


static func block(key: String) -> String:
	return text(key) + "\n" + ref(key)


static func notice() -> String:
	_load()
	return _data["notice"]


## Replace every {key} / {key|block} in a string.
static func resolve(s: String) -> String:
	_load()
	if not "{" in s:
		return s
	var out: String = s
	for m: RegExMatch in _token.search_all(s):
		var key: String = m.get_string(1)
		out = out.replace(m.get_string(), block(key) if m.get_string(2) != "" else caption(key))
	return out
