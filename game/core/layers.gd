class_name Layers
## Physics layer bits (named in project.godot): the town's walls and floors, the player, and the enemies (their
## bodies, which aim rays and projectiles hit).

const WORLD: int = 1
const PLAYER: int = 2
const ENEMY: int = 8
## Render layer bit of the player's meshes, so the player's own fill lights light only the player.
const PLAYER_VISUAL: int = 2
