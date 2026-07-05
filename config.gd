extends Node
## Global tunables — see PROJECT.md §6.4 and §3.

# Viewport
const VIEWPORT_WIDTH := 1920
const VIEWPORT_HEIGHT := 1080
const TARGET_FPS := 60

# Camera (fixed isometric rig — tune here after playtesting)
const CAMERA_FOV := 40.0
const CAMERA_YAW := 45.0
const CAMERA_PITCH := -50.0
const CAMERA_DISTANCE := 20.0
const CAMERA_CHEST_HEIGHT := 0.9
const CAMERA_FOLLOW_SPEED := 8.0

# Movement (M2+)
const GRID_CELL := 1.0
const PLAYER_SPEED := 4.5
const COMPANION_FOLLOW_DISTANCE := 1.25
const INTERACT_RADIUS := 1.5
const COLLISION_INSET := 0.1
const PLAYER_RADIUS := 0.25
const PLAYER_CAPSULE_HEIGHT := 0.7
const COMPANION_SPEED := 3.0
const COMPANION_REPATH_INTERVAL := 0.5
const COMPANION_STUCK_SECONDS := 2.0

# Placeholder colours (PROJECT.md §14)
const COLOR_GROUND := Color("#7CB87C")
const COLOR_STONE := Color("#8A8490")
const COLOR_PLAYER := Color("#E8847A")
const COLOR_COMPANION := Color("#F5E6C8")
const COLOR_NPC := Color("#9B8FA8")
const COLOR_SKY := Color("#A8D8F0")
const COLOR_COLLISION_DEBUG := Color(1.0, 0.2, 0.2, 0.35)
