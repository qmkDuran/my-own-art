class_name Condition
extends RefCounted
## Evaluates the condition strings used in zone and dialogue data.
## Grammar: "flag", "!flag", "has:item", "!has:item", "flag == value", "flag != value".
## Combine with "&" (all) and "|" (any; binds looser than "&"), or pass an Array (all must hold).


static func check(condition: Variant) -> bool:
	if condition == null:
		return true
	if condition is Array:
		for part: Variant in condition:
			if not check(part):
				return false
		return true
	var text := String(condition).strip_edges()
	if text.is_empty():
		return true
	if text.contains("|"):
		for option: String in text.split("|"):
			if check(option):
				return true
		return false
	if text.contains("&"):
		return check(Array(text.split("&")))
	var negate := text.begins_with("!")
	if negate:
		text = text.substr(1).strip_edges()
	return _check_atom(text) != negate


static func _check_atom(text: String) -> bool:
	if text.contains("=="):
		return _compare(text, "==")
	if text.contains("!="):
		return not _compare(text, "!=")
	if text.begins_with("has:"):
		return GameState.inventory.has_item(text.substr(4))
	return GameState.flags.is_set(text)


static func _compare(text: String, operator: String) -> bool:
	var parts := text.split(operator)
	var flag := parts[0].strip_edges()
	var expected := parts[1].strip_edges().trim_prefix("\"").trim_suffix("\"")
	var actual: Variant = GameState.flags.get_value(flag)
	if expected == "false":
		return actual == null or actual == false
	if expected == "true":
		return GameState.flags.is_set(flag)
	return actual != null and str(actual) == expected


## Joins two conditions into one Array condition.
static func combine(a: Variant, b: Variant) -> Array:
	var result: Array = []
	for part: Variant in [a, b]:
		if part == null:
			continue
		if part is Array:
			result.append_array(part)
		else:
			result.append(part)
	return result
