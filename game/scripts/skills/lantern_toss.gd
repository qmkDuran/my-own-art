class_name LanternToss
extends Skill
## Throw the lantern: it lights and burns where it lands while you fight in the dark (your own light shrinks to an
## ember), then comes home. Cast again to call it back early. Tree: heavier impact, longer burn, Beacon
## (exposure), Dark Adept (stronger in the dark), Homecoming, Tether (pulls enemies), Ember Trail.

var _lantern: ThrownLantern


func away() -> bool:
	return _lantern != null and is_instance_valid(_lantern)


func duration() -> float:
	return float(data["duration"]) + val("duration")


func use(target: Vector2) -> void:
	var d: Vector2 = target - p.global_position
	var to: Vector2 = p.global_position + d.limit_length(float(data["range"]))
	var nav: Nav = Game.current.nav
	if not Game.current.layout.walkable_terrain(Game.current.layout.cell_of(to)):
		to = nav.z.center_of(nav.nearest_free(nav.z.cell_of(to)))
	_lantern = ThrownLantern.new()
	_lantern.skill = self
	_lantern.from = p.lantern_pos() + Vector2(0, 40)
	_lantern.to = to
	_lantern.returned.connect(_home)
	fx().add_child(_lantern)
	p.light.thrown = true
	Audio.sfx("lantern_throw", -5.0)


func recall() -> void:
	if away():
		_lantern.go_home()


func _home() -> void:
	p.light.thrown = false


func info() -> Array:
	var r: Vector2 = shown_range(float(data["damage_pct"]))
	var b: Vector2 = shown_range(float(data["burn_pct"]))
	var rows: Array = [["Impact: %d-%d (x%.2f Heavy Iron)" % [r.x, r.y, 1.0 + val("impact_pct") / 100.0], UiDraw.TEXT],
		["Burns %d-%d every %.1f s for %.1f s, light radius %d px" % [b.x, b.y, ThrownLantern.TICK, duration(), roundi(float(data["light_radius"]))], UiDraw.TEXT],
		["Your own light shrinks while it is away. Cast again to recall.", UiDraw.DIM]]
	if rank("dark_adept") > 0:
		rows.append(["Dark Adept: +%d%% damage, +%d%% speed while away" % [roundi(val("more_pct")), roundi(val("move_pct"))], UiDraw.UP])
	return rows
