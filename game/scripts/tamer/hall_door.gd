class_name HallDoor
extends Node2D
## The way back from the route: a stone arch at the route's start. Walk into it and the Gate Hall (which heals
## your team) is through the transition.

const NEAR: float = 26.0
const ARCH := Vector2(44, 52)

var g: TamerGame
var _armed: bool = false                ## you arrive standing below it; it works once you have stepped away


func setup(game: TamerGame, at: Vector2) -> HallDoor:
	g = game
	position = at
	return self


func _process(_delta: float) -> void:
	if g.area != "route" or g.transition.busy or g.battle.on:
		return
	var near: bool = g.trainer.global_position.distance_to(global_position) < NEAR
	if near and _armed:
		_armed = false
		g.go_hall()
	elif not near:
		_armed = true
	queue_redraw()


func _draw() -> void:
	var half: float = ARCH.x * 0.5
	draw_rect(Rect2(Vector2(-half + 6.0, -ARCH.y + 8.0), Vector2(ARCH.x - 12.0, ARCH.y - 8.0)), Pal.c("void"))
	draw_rect(Rect2(Vector2(-half, -ARCH.y), Vector2(ARCH.x, 8)), Pal.c("stone_lt"))
	draw_rect(Rect2(Vector2(-half, -ARCH.y), Vector2(6, ARCH.y)), Pal.c("stone_lt"))
	draw_rect(Rect2(Vector2(half - 6.0, -ARCH.y), Vector2(6, ARCH.y)), Pal.c("stone_lt"))
	UiDraw.text(self, Vector2(-60, -ARCH.y - 6.0), "Gate Hall", UiDraw.GOLD, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, 120.0)
