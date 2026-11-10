extends Node
## Runs .dlg scripts from res://data/dialogue/. A reference is "file#node", e.g. "ch1#dinner"
## (node defaults to "start"). Scripts drive both conversations and cinematic beats.

const DIALOGUE_DIR := "res://data/dialogue/"
const END := "__end__"
const INPUT_COOLDOWN_MSEC := 200

var box: DialogueBox
var commands := ScriptCommands.new()

var _scripts: Dictionary = {}
var _running := false
var _current_ref := ""
var _inline_count := 0
var _finished_msec := -100000


func is_running() -> bool:
	return _running


## True for a moment after a script ends, so the key press that closed the last line does not
## also start a new interaction or swing.
func just_finished() -> bool:
	return Time.get_ticks_msec() - _finished_msec < INPUT_COOLDOWN_MSEC


func current_ref() -> String:
	return _current_ref


func register_box(dialogue_box: DialogueBox) -> void:
	box = dialogue_box


func _has_box() -> bool:
	return box != null and is_instance_valid(box)


func has_ref(ref: String) -> bool:
	var parts := _split_ref(ref)
	return script_file(parts[0]).has_node(parts[1])


## Runs a script node to completion. If another script is running, waits for it first.
func run(ref: String) -> void:
	while _running:
		await Events.dialogue_finished
	var parts := _split_ref(ref)
	var script := script_file(parts[0])
	if not script.has_node(parts[1]):
		push_error("Dialogue node not found: %s" % ref)
		return
	_running = true
	_current_ref = ref
	Events.dialogue_started.emit(ref)
	await _run_from(script, parts[1])
	if _has_box():
		box.close()
	await Router.ensure_visible()
	_running = false
	_finished_msec = Time.get_ticks_msec()
	_current_ref = ""
	Events.dialogue_finished.emit(ref)


## Speaks a few plain lines (used by examine text). speaker defaults to the hero.
func run_lines(lines: Array, speaker: String = "hero") -> void:
	var script := DialogueScript.new()
	var steps: Array = []
	for text: Variant in lines:
		var step := DialogueScript.Step.new()
		step.type = DialogueScript.StepType.SAY
		step.speaker = speaker
		step.text = String(text)
		steps.append(step)
	_inline_count += 1
	var key := "__inline_%d" % _inline_count
	script.source = "inline"
	script.nodes["start"] = steps
	_scripts[key] = script
	await run(key + "#start")
	_scripts.erase(key)


func script_file(file_name: String) -> DialogueScript:
	if _scripts.has(file_name):
		return _scripts[file_name]
	var path := DIALOGUE_DIR + file_name + ".dlg"
	var script: DialogueScript
	if FileAccess.file_exists(path):
		script = DialogueParser.parse(FileAccess.get_file_as_string(path), path)
	else:
		push_error("Dialogue file missing: %s" % path)
		script = DialogueScript.new()
	_scripts[file_name] = script
	return script


func _run_from(script: DialogueScript, start_node: String) -> void:
	var steps := script.steps(start_node)
	var index := 0
	while index < steps.size():
		var step: DialogueScript.Step = steps[index]
		var jump := ""
		match step.type:
			DialogueScript.StepType.SAY:
				if Condition.check(step.condition):
					await Router.ensure_visible()
					await _say(step)
				index += 1
			DialogueScript.StepType.GOTO:
				jump = step.target
			DialogueScript.StepType.CHOICE:
				var group := _choice_group(steps, index)
				var picked := await _choose(group)
				index += group.size()
				jump = picked.target if picked else ""
			DialogueScript.StepType.COMMAND:
				jump = await _command(step)
				index += 1
		if jump == END:
			return
		if not jump.is_empty():
			if not script.has_node(jump):
				push_error("%s:%d: jump to unknown node '%s'" % [script.source, step.line_number, jump])
				return
			steps = script.steps(jump)
			index = 0


func _say(step: DialogueScript.Step) -> void:
	var speaker: Dictionary = DB.speakers.get(step.speaker, {})
	var shown_name := step.display_name if not step.display_name.is_empty() else String(speaker.get("name", step.speaker.capitalize()))
	var portrait_id := _portrait_id(speaker, step.mood)
	var portrait: Texture2D = null if portrait_id.is_empty() else Art.texture(portrait_id)
	if _has_box():
		box.set_portrait_material(null if portrait_id.is_empty() else Art.material_for(portrait_id))
		await box.present_line(GameState.substitute(shown_name), portrait, GameState.substitute(step.text), step.auto_continue)


## The hero has no portrait (speaker "portrait": ""): their lines show only the name.
func _portrait_id(speaker: Dictionary, mood: String) -> String:
	var art_id := String(speaker.get("portrait", ""))
	if not art_id.is_empty() and not mood.is_empty() and Art.has_art(art_id + "_" + mood):
		art_id += "_" + mood
	return art_id


func _choice_group(steps: Array, start: int) -> Array:
	var group: Array = []
	var index := start
	while index < steps.size() and (steps[index] as DialogueScript.Step).type == DialogueScript.StepType.CHOICE:
		group.append(steps[index])
		index += 1
	return group


func _choose(group: Array) -> DialogueScript.Step:
	var available: Array = group.filter(func(c: DialogueScript.Step) -> bool: return Condition.check(c.condition))
	if available.is_empty():
		return null
	var texts: Array[String] = []
	for choice: DialogueScript.Step in available:
		texts.append(GameState.substitute(choice.text))
	var picked_index := 0
	if _has_box():
		picked_index = await box.present_choices(texts)
	var picked: DialogueScript.Step = available[picked_index]
	for flag: String in picked.set_flags:
		var pair := flag.split("=", true, 1)
		GameState.flags.set_flag(pair[0], ScriptCommands.parse_value(pair[1]) if pair.size() > 1 else true)
	return picked


## Returns a node to jump to, END to stop, or "" to continue.
func _command(step: DialogueScript.Step) -> String:
	match step.command:
		"end":
			return END
		"goto":
			return step.args[0]
		"if":
			return _command_if(step.args)
		"close_box":
			if _has_box():
				box.close()
			return ""
		"call":
			var parts := _split_ref(step.args[0])
			var script := script_file(parts[0])
			if not script.has_node(parts[1]):
				push_error("~ call: dialogue node not found: %s" % step.args[0])
				return ""
			await _run_from(script, parts[1])
			return ""
	if commands.is_cinematic(step.command) and _has_box():
		box.close()
	await commands.execute(step.command, step.args)
	return ""


## "~ if <condition> -> node" (or "~ if <condition> end"). The condition may contain spaces.
func _command_if(args: Array[String]) -> String:
	if args.size() < 2:
		return ""
	var target := args[args.size() - 1]
	var condition_tokens := args.slice(0, args.size() - 1)
	if condition_tokens.back() == "->":
		condition_tokens.pop_back()
	if not Condition.check(" ".join(condition_tokens)):
		return ""
	return END if target == "end" else target


func _split_ref(ref: String) -> PackedStringArray:
	var parts := ref.split("#")
	if parts.size() < 2:
		parts.append("start")
	return parts
