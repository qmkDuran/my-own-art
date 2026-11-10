class_name Minimap
extends Control
## A small map in the top-right corner (the ground image at 1/24): Michael, nearby demons, prayers, waystones,
## chests and the rift. Drawn by code.

const SCALE: float = 1.0 / 24.0
const AT_Y: float = 6.0
const W: float = 160.0
const RANGE: float = 900.0

var game: Game
var _tex: Texture2D = preload("res://art/ui/minimap.png")


func setup(g: Game) -> void:
	game = g
	position = Vector2(get_viewport_rect().size.x - W - 8.0, AT_Y)
	size = _tex.get_size()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	visible = not (game.inventory_panel.visible or game.hosts_panel.visible)   # out of the way of the right-hand panels
	position.x = get_viewport_rect().size.x - W - 8.0
	queue_redraw()


func _p(world: Vector2) -> Vector2:
	return world * SCALE


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r.grow(2.0), UiDraw.INK)
	draw_texture(_tex, Vector2.ZERO, Color(0.55, 0.55, 0.7))
	draw_rect(r.grow(1.0), UiDraw.FRAME, false, 1.0)
	var rift: Array = GameData.zone["rift"]
	draw_circle(_p(Vector2(float(rift[0]), float(rift[1]))), 4.0, Color("6e2727"))
	for p: Dictionary in game.objective.points:
		draw_circle(_p(p["at"]), 2.0, Color("fbff86") if int(p["state"]) != PrayerObjective.STATE_ANSWERED else Color("f9c22b"))
	for n: Node in get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		var c: Color = (Color("8fd3ff") if it.opened else Color("4d65b4")) if it.kind == "waystone" else (Color("625565") if it.opened else Color("cd683d"))
		draw_rect(Rect2(_p(it.global_position) - Vector2(1, 1), Vector2(3, 3)), c)
	var m: Vector2 = game.michael.global_position
	for n: Node in get_tree().get_nodes_in_group("demons"):
		var d := n as Demon
		if d.global_position.distance_to(m) < RANGE:
			draw_rect(Rect2(_p(d.global_position), Vector2(1, 1)), Color("e83b3b") if d.rank == "" else Color("f57d4a"))
	draw_circle(_p(m), 2.5, Color.WHITE)
	var view: Vector2 = get_viewport_rect().size / game.camera.zoom
	draw_rect(Rect2(_p(m - view / 2.0), view * SCALE), Color(1, 1, 1, 0.35), false, 1.0)
