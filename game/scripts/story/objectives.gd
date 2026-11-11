class_name Objectives
extends RefCounted
## The tracker's lines (top-left), from the session's state: the main goal, waylamps, secrets.

static func lines(g: Game) -> Array:
	var out: Array = []
	if g.flags.has("slice_done"):
		out.append(["Nim is safe. Explore, or rest.", UiDraw.UP])
	elif g.flags.has("nim_free"):
		out.append(["Talk to Nim", UiDraw.GOLD])
	elif g.flags.has("boss"):
		out.append(["Break the Glazier", UiDraw.GOLD])
	else:
		out.append(["Find Nim Saltry in the Glasswood", UiDraw.GOLD])
	out.append(["Waylamps lit  %d / %d" % [g.lit_lamps(), g.lamps.size()], UiDraw.TEXT])
	out.append(["Secrets found  %d / 1" % (1 if g.flags.has("secret") else 0), UiDraw.DIM])
	return out


## Where the current goal is on the map (INF if none to show).
static func target(g: Game) -> Vector2:
	if g.flags.has("slice_done"):
		return Vector2.INF
	return g.layout.circle_center()
