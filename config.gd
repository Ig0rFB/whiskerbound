extends Node
## Global tunables — see PROJECT.md §6.4.

# Viewport
const VIEWPORT_WIDTH := 2560
const VIEWPORT_HEIGHT := 1440
const TARGET_FPS := 60

# Physics layers (world CSG / static mesh = 1, characters = 2)
const COLLISION_LAYER_WORLD := 1
const COLLISION_LAYER_CHARACTER := 2

# CharacterBody3D defaults for companions, NPCs, and other grounded actors
const CHARACTER_BODY_RADIUS := 0.25
const CHARACTER_BODY_HEIGHT := 0.7
const COMPANION_BODY_RADIUS := 0.22
const COMPANION_BODY_HEIGHT := 0.35
const NPC_BODY_RADIUS := 0.25
const NPC_BODY_HEIGHT := 0.7

# Movement (grid pathfinding + companion follow)
const GRID_CELL := 1.0
const PLAYER_SPEED := 4.5
const COMPANION_FOLLOW_DISTANCE := 1.25
const INTERACT_RADIUS := 1.5
const COLLISION_INSET := 0.1
const COMPANION_SPEED := 3.0
const COMPANION_REPATH_INTERVAL := 0.5
const COMPANION_STUCK_SECONDS := 2.0
const COMPANION_PREDICT_SECONDS := 0.35
const COMPANION_SLOT_LATERAL := 0.4
const COMPANION_MODEL_TARGET_HEIGHT := 0.4
const COMPANION_MODEL_SORT_HEIGHT := 0.2
const COMPANION_WALK_ANIM := "walk"
const COMPANION_WALK_ANIM_SPEED := 1.0
# Radians added to movement-facing yaw (Blender GLB bind pose faces -Z → use PI).
const COMPANION_MODEL_YAW_OFFSET := PI

# Placeholder colours (PROJECT.md §14)
const COLOR_GROUND := Color("#7CB87C")
const COLOR_STONE := Color("#8A8490")
const COLOR_PLAYER := Color("#E8847A")
const COLOR_COMPANION := Color("#F5E6C8")
const COLOR_NPC := Color("#9B8FA8")
const COLOR_SKY := Color("#A8D8F0")
const COLOR_COLLISION_DEBUG := Color(1.0, 0.2, 0.2, 0.35)

# UI / debug (PROJECT.md §12)
const DEBUG_MAX_COMPANIONS := 8
const MINIMAP_PANEL_SIZE := 168
const MINIMAP_MARGIN := 16

# Gamepad (PROJECT.md §11 — SN30 Pro / generic)
const GAMEPAD_DEADZONE := 0.2
# Star / capture on Switch Pro and 8BitDo Switch mode (SDL misc1).
const GAMEPAD_STAR_BUTTON := JOY_BUTTON_MISC1
