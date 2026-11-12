class_name Layers
## Physics layer bits shared by the world, creatures, projectiles, the camera and sight checks.

const TERRAIN: int = 1
const OBSTACLE: int = 2
const CREATURE: int = 4
const HIDING: int = 8
const CANOPY: int = 16
const SIGHT_BLOCKERS: int = TERRAIN | OBSTACLE
const PROJECTILE_HITS: int = TERRAIN | OBSTACLE | CREATURE
const CAMERA_BLOCKERS: int = TERRAIN | OBSTACLE | CANOPY
const CREATURE_MOVES_AGAINST: int = TERRAIN | OBSTACLE | CREATURE
