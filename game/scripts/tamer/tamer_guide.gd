class_name TamerGuide
extends RefCounted
## What to try next, for the tracker: the steps in tamer.json "guide", each done by an event (picked a starter,
## won a fight, used hybrid control, befriended, swapped, rested, raised a stat, unlocked a bond move). The tracker
## shows the first step not yet done, so doing things out of order is fine.

signal changed

var _done: Dictionary = {}


func done(id: String) -> void:
	if not _done.has(id):
		_done[id] = true
		changed.emit()


func is_done(id: String) -> bool:
	return _done.has(id)


func steps() -> Array:
	return TamerData.rule("guide")


func current() -> Dictionary:
	for s: Dictionary in steps():
		if not _done.has(String(s["id"])):
			return s
	return steps()[steps().size() - 1]


## "3/8": steps done out of those that can be done (the last one is open-ended).
func progress() -> String:
	var n: int = steps().size() - 1
	var k: int = 0
	for i: int in n:
		if _done.has(String(steps()[i]["id"])):
			k += 1
	return "%d/%d" % [k, n]
