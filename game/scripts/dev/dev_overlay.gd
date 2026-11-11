class_name DevOverlay
extends Node2D
## Draws what the dev menu asks for over the world: every body's collision circle, and the gameplay radius of every
## light source (the lantern, lit waylamps, thrown lantern).

const BOX := Color(1.0, 0.3, 0.3, 0.8)
const LIGHT := Color(1.0, 0.85, 0.3, 0.8)


func _ready() -> void:
	z_index = Fx.FX_Z + 1


func _process(_delta: float) -> void:
	visible = Dev.show_boxes or Dev.show_light
	if visible:
		queue_redraw()


func _draw() -> void:
	if Dev.show_boxes:
		for n: Node in get_tree().get_nodes_in_group("enemies"):
			var e := n as Enemy
			draw_arc(e.global_position, e.radius, 0.0, TAU, 24, BOX, 1.0)
		var p: Player = Game.current.player
		draw_arc(p.global_position, p.radius, 0.0, TAU, 24, BOX, 1.0)
	if Dev.show_light:
		for n: Node in get_tree().get_nodes_in_group(LightField.GROUP):
			if n.has_method("light_radius"):
				draw_arc(n.call("light_pos"), float(n.call("light_radius")), 0.0, TAU, 48, LIGHT, 1.0)
