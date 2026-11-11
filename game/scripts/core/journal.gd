class_name Journal
extends RefCounted
## The field journal: which species you have seen and which have befriended you.

var seen: Dictionary = {}
var befriended: Dictionary = {}


func see(id: String) -> void:
	seen[id] = true


func befriend(id: String) -> void:
	seen[id] = true
	befriended[id] = true


func befriended_count() -> int:
	return befriended.size()


func status(id: String) -> String:
	if befriended.has(id):
		return "befriended"
	return "seen" if seen.has(id) else "unknown"
