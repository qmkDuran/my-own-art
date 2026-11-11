class_name ZoneGen
extends RefCounted
## Lays out a zone from biome rules (data/glasswood.json) and a seed, in an order where each step has a reason:
## geography (wall, stream, clearings, ponds), paths and bridges, the closed border, set-pieces and edge details,
## the forest, and the enemy packs. make() retries the next seed if LayoutCheck finds any problem, so a broken
## zone is never shown.

const MAX_TRIES: int = 12
const SEED_STEP: int = 7919


## A zone that passed every layout check (tries following seeds if needed).
static func make(biome: Dictionary, seed_value: int) -> ZoneLayout:
	for k: int in MAX_TRIES:
		var layout: ZoneLayout = generate(biome, seed_value + k * SEED_STEP)
		if LayoutCheck.problems(layout).is_empty():
			return layout
	push_error("ZoneGen: no valid layout near seed %d" % seed_value)
	return generate(biome, seed_value)


static func generate(biome: Dictionary, seed_value: int) -> ZoneLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.08
	var z := ZoneLayout.new()
	z.setup(int(biome["cols"]), int(biome["rows"]), int(biome["cell"]), seed_value)
	if biome.get("city", false):
		(CityGen.new().with(z, biome, rng, noise) as CityGen).run()
		return z
	var geo := ZoneGeography.new().with(z, biome, rng, noise) as ZoneGeography
	geo.run()
	(ZonePaths.new().with(z, biome, rng, noise) as ZonePaths).run()
	geo.close_border()
	(ZonePlacement.new().with(z, biome, rng, noise) as ZonePlacement).run()
	(ZoneForest.new().with(z, biome, rng, noise) as ZoneForest).run()
	(ZonePacks.new().with(z, biome, rng, noise) as ZonePacks).run()
	return z
