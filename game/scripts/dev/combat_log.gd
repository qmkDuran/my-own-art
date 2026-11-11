class_name CombatLog
extends RefCounted
## The last moments of combat, as text lines with their time: what hit what, for how much. Feedback notes carry the
## last 30 s; the session log takes a death's cause from it. Only kept when Dev tools are on.

const KEEP: float = 30.0

static var _lines: Array = []           ## [seconds, text]


static func add(text: String) -> void:
	if not Dev.enabled():
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	_lines.append([now, text])
	while not _lines.is_empty() and now - float(_lines[0][0]) > KEEP:
		_lines.pop_front()


static func recent() -> PackedStringArray:
	var now: float = Time.get_ticks_msec() / 1000.0
	var out := PackedStringArray()
	for l: Array in _lines:
		out.append("-%5.1fs  %s" % [now - float(l[0]), l[1]])
	return out


## What last hit the Lamplighter (the cause of a death).
static func last_hit_on_player() -> String:
	for i: int in range(_lines.size() - 1, -1, -1):
		if String(_lines[i][1]).contains("-> Lamplighter"):
			return String(_lines[i][1])
	return "unknown"
