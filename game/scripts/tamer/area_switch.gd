class_name AreaSwitch
extends Node
## Moves you between the demo's places: the Gate Hall, the route and an arena. Only the active place is visible and
## running (the route's wild creatures wait while you are away); the trainer moves to it, your creature comes along
## (in an arena the battle places it), and the camera takes the place's bounds.

const ARENA_MARGIN: float = 600.0       ## the camera never reaches an arena's bounds: it stays fixed on its centre
const HALL_TOP: float = 60.0

var g: TamerGame
var _hall_nav: Nav


func setup(game: TamerGame) -> void:
	g = game


## The demo starts in the Gate Hall with the default team (tamer.json "hall").
func go_hall_start() -> void:
	var H: Dictionary = TamerData.rule("hall")
	enter_hall(g.hall.spot("you"))
	g.hud.station.choose(H["default_team"], int(H["default_level"]))
	g.camera.reset_smoothing()


func enter_hall(at: Vector2) -> void:
	if _hall_nav == null:
		_hall_nav = Nav.new(g.hall.layout)
	g.team.rest()                                          # the hall heals everyone
	_activate("hall", g.hall.layout, _hall_nav, g.hall.stage, g.hall.layout.rect_px().grow_individual(0, HALL_TOP, 0, 0), at)


func enter_route(at: Vector2) -> void:
	_activate("route", g.route_layout, g.route_nav, g.route_root, Rect2(Vector2.ZERO, g.route_layout.size_px()), at)


func enter_arena(a: Arena) -> void:
	_activate("arena", a.layout, Nav.new(a.layout), a.stage, a.layout.rect_px().grow(ARENA_MARGIN), a.trainer_spot(true))


func _activate(name: String, lay: ZoneLayout, nv: Nav, root: Node2D, bounds: Rect2, at: Vector2) -> void:
	g.area = name
	g.layout = lay
	g.nav = nv
	g.world = root
	_show(g.route_view, name == "route")
	_show(g.route_root, name == "route")
	_show(g.hall, name == "hall")
	g.ambient.color = Atmosphere.ambient(GameData.biome) if name == "route" else Color.WHITE
	g.field.recall_now()
	g.trainer.reparent(root)
	g.trainer.place(at)
	if name != "arena" and g.team.current() != null:
		g.field.summon(g.team.active, false)
	_bound(bounds)


func _show(n: CanvasItem, on: bool) -> void:
	n.visible = on
	n.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func _bound(r: Rect2) -> void:
	g.camera.limit_left = int(r.position.x)
	g.camera.limit_top = int(r.position.y)
	g.camera.limit_right = int(r.end.x)
	g.camera.limit_bottom = int(r.end.y)
	g.focus.global_position = g.trainer.global_position
	g.camera.global_position = g.trainer.global_position
	g.camera.reset_smoothing()
