extends Node
## --layout: generates every zone for many seeds (the hub once: it is laid by hand), prints every rule broken
## (LayoutCheck) and, with --map=<zone>, writes that zone's debug map (terrain, footprints, trees, packs).

const SEEDS: int = 16
const PX: int = 4
const COLORS: Dictionary = {0: Color("1a2420"), 1: Color("3b4d3a"), 2: Color("6b5040"), 3: Color("2f7d84"), 4: Color("a07040"),
	5: Color("75727e"), 6: Color("2c2b33")}


func _ready() -> void:
	GameData.ensure()
	var ok: bool = true
	for id: String in GameData.zones["zones"]:
		ok = _zone(id) and ok
	print("LAYOUT PASS" if ok else "LAYOUT FAIL")
	get_tree().quit()


func _zone(id: String) -> bool:
	GameData.use_zone(id)
	var seeds: int = 1 if GameData.biome.get("city", false) else SEEDS
	var base: int = int(GameData.zone(id)["seed"])
	var bad: int = 0
	var t0: int = Time.get_ticks_msec()
	for s: int in seeds:
		var z: ZoneLayout = ZoneGen.generate(GameData.biome, base + s)
		var probs: PackedStringArray = LayoutCheck.problems(z)
		if not probs.is_empty():
			bad += 1
			print("LAYOUT %s seed %d: %d problems, e.g. %s" % [id, base + s, probs.size(), "; ".join(probs.slice(0, 3))])
		if s == 0 and _map_zone() == id:
			_dump(z, id)
	var final: PackedStringArray = LayoutCheck.problems(ZoneGen.make(GameData.biome, base))
	print("LAYOUT %s: %d/%d raw seeds clean, %.0f ms per zone; the retrying generator gives %s" % [id, seeds - bad, seeds,
		float(Time.get_ticks_msec() - t0) / seeds, "a clean zone" if final.is_empty() else "PROBLEMS: " + "; ".join(final.slice(0, 3))])
	return final.is_empty() and bad * 2 < seeds + 1


func _map_zone() -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			return a.substr(6)
	return ""


func _dump(z: ZoneLayout, id: String) -> void:
	var img := Image.create(z.cols * PX, z.rows * PX, false, Image.FORMAT_RGBA8)
	for y: int in z.rows:
		for x: int in z.cols:
			img.fill_rect(Rect2i(x * PX, y * PX, PX, PX), COLORS[z.t(Vector2i(x, y))])
	var k: float = float(PX) / z.cell
	for t: Dictionary in z.trees:
		img.set_pixelv(Vector2i((t["pos"] as Vector2) * k), Color("57b8b0"))
	for p: Dictionary in z.props:
		var r: Rect2 = p["foot"]
		img.fill_rect(Rect2i(Vector2i(r.position * k), Vector2i((r.size * k).ceil()).max(Vector2i(2, 2))), Color("ffd77a"))
	for s: Dictionary in z.spawns:
		img.fill_rect(Rect2i(Vector2i((s["pos"] as Vector2) * k) - Vector2i(1, 1), Vector2i(3, 3)), Color("e8505a"))
	img.fill_rect(Rect2i(Vector2i(z.start * k) - Vector2i(3, 3), Vector2i(6, 6)), Color.WHITE)
	img.save_png(TestRunner.out_dir() + "/layout_%s.png" % id)
