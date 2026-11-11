extends Node
## --layout: generates the Glasswood for many seeds, prints every rule broken (LayoutCheck) and, with --map,
## writes a debug map of the first seed (terrain, footprints, trees, packs) to the out directory.

const SEEDS: int = 24
const PX: int = 4
const COLORS: Dictionary = {0: Color("1a2420"), 1: Color("3b4d3a"), 2: Color("6b5040"), 3: Color("2f7d84"), 4: Color("a07040"),
	5: Color("75727e"), 6: Color("2c2b33")}


func _ready() -> void:
	GameData.ensure()
	var bad: int = 0
	var t0: int = Time.get_ticks_msec()
	for s: int in SEEDS:
		var z: ZoneLayout = ZoneGen.new().generate(GameData.biome, 1000 + s)
		var probs: PackedStringArray = LayoutCheck.problems(z)
		if not probs.is_empty():
			bad += 1
			print("LAYOUT seed %d: %d problems, e.g. %s" % [1000 + s, probs.size(), "; ".join(probs.slice(0, 4))])
		if 1000 + s == _map_seed():
			_dump(z)
	var ms: float = float(Time.get_ticks_msec() - t0) / SEEDS
	var z_ok: ZoneLayout = ZoneGen.make(GameData.biome, 1000)
	var final: PackedStringArray = LayoutCheck.problems(z_ok)
	print("LAYOUT %d/%d raw seeds clean, %.0f ms per zone; the retrying generator gives %s" % [SEEDS - bad, SEEDS, ms,
		"a clean zone" if final.is_empty() else "PROBLEMS"])
	print("LAYOUT PASS" if final.is_empty() and bad * 3 < SEEDS else "LAYOUT FAIL")
	get_tree().quit()


func _map_seed() -> int:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			return int(a.substr(6))
	return -1


func _dump(z: ZoneLayout) -> void:
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
		var c: Color = Color("e8505a") if s["rank"] == "normal" else Color("f07a24")
		img.fill_rect(Rect2i(Vector2i((s["pos"] as Vector2) * k) - Vector2i(1, 1), Vector2i(3, 3)), c)
	img.fill_rect(Rect2i(Vector2i(z.start * k) - Vector2i(3, 3), Vector2i(6, 6)), Color.WHITE)
	img.fill_rect(Rect2i(Vector2i((z.boss["pos"] as Vector2) * k) - Vector2i(4, 4), Vector2i(8, 8)), Color("a070d8"))
	img.save_png(TestRunner.out_dir() + "/layout_map.png")
