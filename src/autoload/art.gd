extends Node
## Resolves art ids (data/art.json) to textures.
## Each entry may name a "path" (a PNG under res://art/). If that file exists it is used;
## otherwise a placeholder is painted from the entry's "placeholder" spec. Swapping art is
## therefore just dropping a PNG at the path listed in art.json.

var _logged_missing: Dictionary = {}

var _cache: Dictionary = {}
var _layouts: Dictionary = {}


func texture(art_id: String) -> Texture2D:
	if _cache.has(art_id):
		return _cache[art_id]
	var tex := _load_or_paint(art_id)
	_cache[art_id] = tex
	return tex


func has_art(art_id: String) -> bool:
	return DB.art.has(art_id)


func entry(art_id: String) -> Dictionary:
	var raw: Dictionary = DB.art.get(art_id, {})
	if raw.has("extends"):
		var merged := entry(String(raw["extends"])).duplicate(true)
		var placeholder: Dictionary = merged.get("placeholder", {})
		placeholder.merge(raw.get("placeholder", {}), true)
		merged.merge(raw, true)
		merged["placeholder"] = placeholder
		merged.erase("extends")
		return merged
	return raw


## Sprite-sheet layout for animated art: {"hframes", "vframes", "rows": {"down","up","side"}, "fps"}.
func sheet(art_id: String) -> Dictionary:
	return entry(art_id).get("sheet", {})


## True when the entry's PNG exists (not a painted placeholder).
func has_real_texture(art_id: String) -> bool:
	var path := String(entry(art_id).get("path", ""))
	return not path.is_empty() and ResourceLoader.exists(path)


## Animation layout of a full character sheet ("sheet": {"layout": "res://...json"}), as
## {anim: {dir: {"row", "frames", "fps", "loop"}}}. Empty when the entry has none.
func layout(art_id: String) -> Dictionary:
	if _layouts.has(art_id):
		return _layouts[art_id]
	var result: Dictionary = {}
	var path := String(sheet(art_id).get("layout", ""))
	if not path.is_empty() and FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			for row: Variant in (parsed as Dictionary).get("rows", []):
				var r: Dictionary = row
				var anim := String(r.get("anim", ""))
				if not result.has(anim):
					result[anim] = {}
				(result[anim] as Dictionary)[String(r.get("dir", "down"))] = r
	_layouts[art_id] = result
	return result


## The skin palette-swap material for art marked "skin_swap": true (hero body, Mom, Mom's
## portrait), using the hero's chosen skin tone; null for everything else.
func material_for(art_id: String) -> Material:
	if not entry(art_id).get("skin_swap", false):
		return null
	return SkinPalette.material(GameState.skin_color())


func _load_or_paint(art_id: String) -> Texture2D:
	var data := entry(art_id)
	if data.is_empty():
		_log_missing_once(art_id)
		return ImageTexture.create_from_image(PlaceholderPainter.paint({"shape": "missing"}, art_id))
	var path := String(data.get("path", ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		var loaded: Texture2D = load(path)
		if loaded:
			return loaded
	var image := PlaceholderPainter.paint(data.get("placeholder", {}), art_id)
	return ImageTexture.create_from_image(image)


func _log_missing_once(art_id: String) -> void:
	if _logged_missing.has(art_id):
		return
	_logged_missing[art_id] = true
	print("[Art] No art entry for '%s'; using a magenta placeholder." % art_id)
