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
const NPC_BODY_RADIUS := 0.35
const NPC_BODY_HEIGHT := 2.2
const NPC_FLOATING_BODY_RADIUS := 0.45
const NPC_FLOATING_BODY_HEIGHT := 1.2
## Minimum cylinder span for floating NPC ground columns (Bat interaction).
const NPC_FLOATING_COLUMN_MIN_HEIGHT := 0.5
## Local Y top for floating columns — must reach chest-height rays (InteractionRaycast ~1 m).
const NPC_FLOATING_COLUMN_TOP_LOCAL := 1.5
const NPC_FLOATING_GROUND_RAY_ABOVE := 1.0
const NPC_FLOATING_GROUND_RAY_BELOW := 50.0
## Physics frames to retry the floor ray before building a floating column with a fallback floor.
const NPC_FLOATING_COLUMN_MAX_ATTEMPTS := 8

# Movement (grid pathfinding + companion follow)
const GRID_CELL := 1.0
const PLAYER_SPEED := 4.5
const COMPANION_FOLLOW_DISTANCE := 1.25
const INTERACT_RADIUS := 1.5
const INTERACTION_RAY_LENGTH := 4.0
const INTERACTION_HIGHLIGHT_COLOUR := Color(0.35, 0.75, 1.0, 0.55)
const INTERACTION_HIGHLIGHT_ENERGY := 0.6
const INTERACTION_FOCUS_COLOUR := Color(1.0, 0.92, 0.35, 0.85)
const INTERACTION_FOCUS_ENERGY := 1.4
const COLLISION_INSET := 0.1
const COMPANION_SPEED := 3.0
const COMPANION_REPATH_INTERVAL := 0.5
const COMPANION_STUCK_SECONDS := 2.0
const COMPANION_PREDICT_SECONDS := 0.35
const COMPANION_SLOT_LATERAL := 0.4
const COMPANION_MODEL_TARGET_HEIGHT := 0.4
const COMPANION_MODEL_SORT_HEIGHT := 0.2
## Lifts fitted mesh above the floor contact to avoid paw clipping (coplanar z-fight).
const COMPANION_MESH_FLOOR_CLEARANCE := 0.15
const COMPANION_WALK_ANIM := "walk"
const COMPANION_WALK_ANIM_SPEED := 1.0
# Placeholder names — wire when cat.glb gains clips (§9.2; see companion logic.md).
const COMPANION_ANIM_SIT := "sit"
const COMPANION_ANIM_PLAY := "play"
const COMPANION_ANIM_GROOM := "groom"
const COMPANION_IDLE_ENTER_SECONDS := 2.0
const COMPANION_WANDER_RADIUS := 2.5
const COMPANION_ACTIVITY_MIN_SECONDS := 3.0
const COMPANION_ACTIVITY_MAX_SECONDS := 8.0
const COMPANION_MEOW_MIN_INTERVAL := 15.0
const COMPANION_MEOW_MAX_INTERVAL := 45.0
const COMPANION_BARK_DURATION := 2.5
# Radians added to movement-facing yaw (Blender GLB bind pose faces -Z → use PI).
const COMPANION_MODEL_YAW_OFFSET := PI

# Companion navigation (NavigationAgent3D + runtime-baked NavigationRegion3D — PROJECT.md §4).
# Navmesh bake parameters (applied to the region's NavigationMesh before baking).
const NAV_SOURCE_GROUP := "navigation_source"
## Cell size/height match the default navigation map (0.25) to avoid rasterisation mismatch.
## Agent radius/height/climb are exact multiples of the cell dims to avoid precision ceiling.
const NAV_CELL_SIZE := 0.25
const NAV_CELL_HEIGHT := 0.25
const NAV_AGENT_RADIUS := 0.25
const NAV_AGENT_HEIGHT := 0.5
## Max vertical ledge the bake will bridge — keeps the CSG-top surfaces connected.
const NAV_AGENT_MAX_CLIMB := 0.5
const NAV_AGENT_MAX_SLOPE_DEG := 45.0
## Baked navmesh resource shipped with the playground (regenerate via scenes/tools/bake_playground_navmesh.gd).
const PLAYGROUND_NAVMESH_PATH := "res://scenes/areas/playground_navmesh.tres"
# NavigationAgent3D behaviour on the companion.
const COMPANION_NAV_PATH_DESIRED_DISTANCE := 0.4
const COMPANION_NAV_TARGET_DESIRED_DISTANCE := 0.4
## How often the follow goal is pushed to the agent (s); the agent repaths internally as needed.
const COMPANION_NAV_GOAL_INTERVAL := 0.2
## Distance from the goal at which the companion eases to a stop (avoids overshoot jitter).
const COMPANION_NAV_ARRIVE_SLOWDOWN := 0.6

# Editor floor snap for scene-placed companions (raycast above/below current XZ)
const EDITOR_FLOOR_SNAP_RAY_ABOVE := 20.0
const EDITOR_FLOOR_SNAP_RAY_BELOW := 50.0

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

# Camera zoom (TPC spring arm — wheel is discrete, keys/triggers are continuous)
const CAMERA_ZOOM_SPEED := 10.0
const CAMERA_ZOOM_WHEEL_STEP := 1.0

# Gamepad (PROJECT.md §11 — SN30 Pro / generic)
const GAMEPAD_DEADZONE := 0.2
# Star / capture on Switch Pro and 8BitDo Switch mode (SDL misc1).
const GAMEPAD_STAR_BUTTON := JOY_BUTTON_MISC1
