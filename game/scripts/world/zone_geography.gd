class_name ZoneGeography
extends GenStep
## Geography first: Tallow's wall and its cleared strip, the glass stream, the clearings (kept away from the
## water and from each other), ponds inside their clearings, and finally the closed map border.


const PLACE_TRIES: int = 600


func run() -> void:
	_wall()
	_stream()
	_clearings()
	_ponds()


func close_border() -> void:
	_border()


func _wall() -> void:
	var w: Dictionary = b["wall"]
	z.wall_cols = int(w["cols"])
	z.wall_rows = int(w["rows"])
	z.gate_col = int(w["gate_col"])
	for y: int in z.wall_rows:
		for x: int in z.wall_cols:
			z.set_t(Vector2i(x, y), T.WALL)
	z.start = Vector2((z.gate_col + 2) * z.cell, (z.wall_rows + 2.5) * z.cell)
	for y: int in range(z.wall_rows, z.wall_rows + 2):            # the city keeps a cleared strip below its wall
		for x: int in range(int(b["border"]), z.wall_cols):
			z.set_t(Vector2i(x, y), T.MOSS)


func stream_x(row: float) -> float:
	var s: Dictionary = b["stream"]
	var amp: Array = s["amp"]
	var fr: Array = s["freq"]
	return z.cols * float(s["x_frac"]) + sin(row * float(fr[0]) + float(z.seed % 97)) * float(amp[1]) \
		+ sin(row * float(fr[1]) + float(z.seed % 13)) * float(amp[0])


func _stream() -> void:
	var half: int = int(b["stream"]["width"]) / 2
	z.stream_center.resize(z.rows)
	for y: int in z.rows:
		z.stream_center[y] = stream_x(y)
		var cx: int = roundi(stream_x(y))
		for x: int in range(cx - half, cx + half + 1):
			var c := Vector2i(x, y)
			if z.inside(c) and z.t(c) != T.WALL:
				z.set_t(c, T.WATER)
				z.stream[z.idx(c)] = 1


func _clearings() -> void:
	for spec: Dictionary in b["clearings"]:
		var r := Vector2(float(spec["r"][0]), float(spec["r"][1]))
		var at: Vector2i = _clearing_spot(spec, r)
		if at.x < 0:
			continue
		var c := {"role": String(spec["role"]), "center": at, "r": r, "secret": bool(spec.get("secret", false))}
		z.clearings.append(c)
		_carve_clearing(z.clearings.size() - 1)


func _clearing_spot(spec: Dictionary, r: Vector2) -> Vector2i:
	if spec.has("at"):
		return Vector2i(int(spec["at"][0]), int(spec["at"][1]))
	if spec.has("at_frac"):
		return Vector2i(roundi(z.cols * float(spec["at_frac"][0])), roundi(z.rows * float(spec["at_frac"][1])))
	var margin: int = int(b["border"]) + 3
	for k: int in PLACE_TRIES:
		var c := Vector2i(rng.randi_range(margin + int(r.x), z.cols - margin - int(r.x)),
			rng.randi_range(margin + int(r.y), z.rows - margin - int(r.y)))
		if _clearing_ok(c, r):
			return c
	return Vector2i(-1, -1)


func _clearing_ok(c: Vector2i, r: Vector2) -> bool:
	if c.x - r.x < z.wall_cols + 2 and c.y - r.y < z.wall_rows + 3:
		return false
	for y: int in range(c.y - int(r.y) - 1, c.y + int(r.y) + 2):
		if absf(stream_x(y) - c.x) < r.x + 4.0:
			return false
	for o: Dictionary in z.clearings:
		var oc: Vector2i = o["center"]
		var orad: Vector2 = o["r"]
		if Vector2(oc).distance_to(Vector2(c)) < maxf(r.x, r.y) + maxf(orad.x, orad.y) + float(b["clearing_spacing"]) * 0.5:
			return false
	return true


func _carve_clearing(i: int) -> void:
	var c: Dictionary = z.clearings[i]
	var ctr: Vector2i = c["center"]
	var r: Vector2 = c["r"]
	for y: int in range(ctr.y - int(r.y) - 2, ctr.y + int(r.y) + 3):
		for x: int in range(ctr.x - int(r.x) - 2, ctr.x + int(r.x) + 3):
			var cc := Vector2i(x, y)
			var d: float = Vector2(float(x - ctr.x) / r.x, float(y - ctr.y) / r.y).length()
			if d < 1.0 + noise.get_noise_2d(x * 3.0, y * 3.0) * 0.18 and z.t(cc) == T.THICKET:
				z.set_t(cc, T.MOSS)
				z.clearing_id[z.idx(cc)] = i


func _ponds() -> void:
	for i: int in z.clearings.size():
		for sp: Dictionary in b["setpieces"].get(z.clearings[i]["role"], []):
			if sp["kind"] != "pond":
				continue
			var ctr: Vector2 = z.center_of(z.clearings[i]["center"]) + _vec(sp["at"])
			var rr := Vector2(float(sp["r"][0]), float(sp["r"][1])) * z.cell
			z.pond = Vector4(ctr.x, ctr.y, rr.x, rr.y)
			for y: int in range(z.cell_of(ctr).y - 4, z.cell_of(ctr).y + 5):
				for x: int in range(z.cell_of(ctr).x - 7, z.cell_of(ctr).x + 8):
					var cc := Vector2i(x, y)
					var p: Vector2 = z.center_of(cc) - ctr
					if Vector2(p.x / rr.x, p.y / rr.y).length() < 1.0 and z.clearing_id[z.idx(cc)] == i:
						z.set_t(cc, T.WATER)


func _border() -> void:
	var e: int = int(b["border"])
	for y: int in z.rows:
		for x: int in z.cols:
			if (x < e or y < e or x >= z.cols - e or y >= z.rows - e) and z.t(Vector2i(x, y)) != T.WALL:
				z.set_t(Vector2i(x, y), T.THICKET)
				z.stream[z.idx(Vector2i(x, y))] = 0
