class_name ExamineInteractable
extends Interactable
## Shows a few lines of description, or runs a dialogue node ("dialogue": "file#node").

var lines: Array = []
var ref := ""


func setup(data: Dictionary) -> void:
	verb = String(data.get("verb", "Examine"))
	lines = data.get("lines", [])
	if data.has("text"):
		lines = [data["text"]]
	ref = String(data.get("dialogue", ""))
	configure_lock(data)


func _perform(_player: Player) -> void:
	if not ref.is_empty():
		await Dialogue.run(ref)
	elif not lines.is_empty():
		await Dialogue.run_lines(lines)
