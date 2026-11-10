class_name DialogueParser
extends RefCounted
## Parses the plain-text .dlg format into a DialogueScript.
##
##   == node_name                      starts a node
##   speaker: Text                     a line (speaker ids in data/speakers.json)
##   speaker(mood): Text               same, with a portrait variant (portrait_<id>_<mood>)
##   speaker[Shown Name]: Text         same, overriding the name shown in the box
##   {condition} speaker: Text         the line only plays when the condition holds
##   speaker: Text >>                  "--" style interrupted line: continue without waiting for input
##   Text without a speaker            narration
##   * Choice text -> node +flag       a choice; optional {condition} prefix, +flag or +flag=value to set
##   -> node                           jump
##   ~ command arg "quoted arg"        a command (see ScriptCommands)
##   # comment  /  // comment

static var _say_regex: RegEx


static func parse(text: String, source: String = "") -> DialogueScript:
	var script := DialogueScript.new()
	script.source = source
	var current := ""
	var line_number := 0
	for raw: String in text.split("\n"):
		line_number += 1
		var line := raw.strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with("//"):
			continue
		if line.begins_with("=="):
			current = line.trim_prefix("==").strip_edges().trim_suffix("==").strip_edges()
			script.nodes[current] = []
			continue
		if current.is_empty():
			push_error("%s:%d: line outside of a '== node'" % [source, line_number])
			continue
		var step := _parse_step(line)
		step.line_number = line_number
		(script.nodes[current] as Array).append(step)
	return script


static func _parse_step(line: String) -> DialogueScript.Step:
	if line.begins_with("->"):
		var jump := DialogueScript.Step.new()
		jump.type = DialogueScript.StepType.GOTO
		jump.target = line.trim_prefix("->").strip_edges()
		return jump
	if line.begins_with("*"):
		return _parse_choice(line.trim_prefix("*").strip_edges())
	if line.begins_with("~"):
		return _parse_command(line.trim_prefix("~").strip_edges())
	return _parse_say(line)


static func _parse_choice(body: String) -> DialogueScript.Step:
	var step := DialogueScript.Step.new()
	step.type = DialogueScript.StepType.CHOICE
	if body.begins_with("{"):
		var close := body.find("}")
		step.condition = body.substr(1, close - 1).strip_edges()
		body = body.substr(close + 1).strip_edges()
	var arrow := body.find("->")
	if arrow == -1:
		step.text = body
		return step
	step.text = body.substr(0, arrow).strip_edges()
	for token: String in body.substr(arrow + 2).strip_edges().split(" ", false):
		if token.begins_with("+"):
			step.set_flags.append(token.substr(1))
		elif step.target.is_empty():
			step.target = token
	return step


static func _parse_command(body: String) -> DialogueScript.Step:
	var step := DialogueScript.Step.new()
	step.type = DialogueScript.StepType.COMMAND
	var tokens := tokenize(body)
	if not tokens.is_empty():
		step.command = tokens.pop_front()
		step.args = tokens
	return step


static func _parse_say(line: String) -> DialogueScript.Step:
	var step := DialogueScript.Step.new()
	step.type = DialogueScript.StepType.SAY
	if line.begins_with("{"):
		var close := line.find("}")
		step.condition = line.substr(1, close - 1).strip_edges()
		line = line.substr(close + 1).strip_edges()
	if line.ends_with(">>"):
		step.auto_continue = true
		line = line.trim_suffix(">>").strip_edges()
	if _say_regex == null:
		_say_regex = RegEx.create_from_string("^([a-z][a-z0-9_]*)(?:\\[([^\\]]+)\\])?(?:\\(([a-z0-9_]+)\\))?:\\s*(.*)$")
	var found := _say_regex.search(line)
	if found:
		step.speaker = found.get_string(1)
		step.display_name = found.get_string(2)
		step.mood = found.get_string(3)
		step.text = found.get_string(4).replace("\\n", "\n")
	else:
		step.speaker = "narrator"
		step.text = line
	return step


## Splits on spaces, keeping "quoted strings" together.
static func tokenize(text: String) -> Array[String]:
	var tokens: Array[String] = []
	var current := ""
	var quoted := false
	for character: String in text:
		if character == "\"":
			quoted = not quoted
			if not quoted:
				tokens.append(current)
				current = ""
		elif character == " " and not quoted:
			if not current.is_empty():
				tokens.append(current)
			current = ""
		else:
			current += character
	if not current.is_empty():
		tokens.append(current)
	return tokens
