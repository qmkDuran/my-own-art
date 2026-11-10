class_name DialogueScript
extends RefCounted
## A parsed .dlg file: named nodes, each an ordered list of steps. See README "Writing dialogue".

enum StepType { SAY, CHOICE, GOTO, COMMAND }


class Step:
	extends RefCounted
	var type: StepType
	var line_number := 0
	var speaker := ""
	var mood := ""
	var display_name := ""
	var auto_continue := false
	var text := ""
	var target := ""
	var condition := ""
	var set_flags: Array[String] = []
	var command := ""
	var args: Array[String] = []


var source := ""
var nodes: Dictionary = {}   # node name -> Array[Step]


func has_node(node_name: String) -> bool:
	return nodes.has(node_name)


func steps(node_name: String) -> Array:
	return nodes.get(node_name, [])
