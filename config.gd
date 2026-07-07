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
const INTERACT_RADIUS := 1.5
const INTERACTION_RAY_LENGTH := 4.0
const INTERACTION_HIGHLIGHT_COLOUR := Color(0.35, 0.75, 1.0, 0.55)
const INTERACTION_HIGHLIGHT_ENERGY := 0.6
const INTERACTION_FOCUS_COLOUR := Color(1.0, 0.92, 0.35, 0.85)
const INTERACTION_FOCUS_ENERGY := 1.4
const COLLISION_INSET := 0.1
const COMPANION_SPEED := 3.0
## Fall recovery: if a companion drops this far below the player (fell off a ledge onto a lower
## level) and stays there this long, it snaps back onto the navmesh beside the player.
const COMPANION_FALL_RECOVER_HEIGHT := 3.0
const COMPANION_STUCK_SECONDS := 2.0
const COMPANION_PREDICT_SECONDS := 0.35
const COMPANION_SLOT_LATERAL := 0.4
const COMPANION_MODEL_TARGET_HEIGHT := 0.4
## Lifts fitted mesh above the floor contact to avoid paw clipping (coplanar z-fight).
const COMPANION_MESH_FLOOR_CLEARANCE := 0.15
const COMPANION_WALK_ANIM := "walk"
const COMPANION_WALK_ANIM_SPEED := 1.0
# Placeholder names — wire when cat.glb gains clips (§9.2; see companion logic.md).
const COMPANION_ANIM_SIT := "sit"
const COMPANION_ANIM_PLAY := "play"
const COMPANION_ANIM_GROOM := "groom"
const COMPANION_WANDER_RADIUS := 3.5
const COMPANION_ACTIVITY_MIN_SECONDS := 3.0
const COMPANION_ACTIVITY_MAX_SECONDS := 8.0
const COMPANION_MEOW_MIN_INTERVAL := 15.0
const COMPANION_MEOW_MAX_INTERVAL := 30.0
const COMPANION_BARK_DURATION := 2.5
# Radians added to movement-facing yaw (Blender GLB bind pose faces -Z → use PI).
const COMPANION_MODEL_YAW_OFFSET := PI

# Companion navigation (NavigationAgent3D + runtime-baked NavigationRegion3D — PROJECT.md §4).
# Navmesh bake parameters (applied to the region's NavigationMesh before baking).
const NAV_SOURCE_GROUP := "navigation_source"
## Cell size/height match the default navigation map (0.25) to avoid rasterisation mismatch.
## Agent radius/height/climb are exact multiples of the cell dims to avoid precision ceiling.
const NAV_CELL_SIZE := 0.25
## Fine cell height keeps the baked navmesh close to the walk surface so agents below it still
## advance waypoints (NavigationAgent3D measures arrival in 3D). The nav map is set to match.
const NAV_CELL_HEIGHT := 0.1
const NAV_AGENT_RADIUS := 0.25
const NAV_AGENT_HEIGHT := 0.5
## Max vertical ledge the bake will bridge — keeps the CSG-top surfaces connected.
const NAV_AGENT_MAX_CLIMB := 0.5
const NAV_AGENT_MAX_SLOPE_DEG := 45.0
## Baked navmesh resource shipped with the playground (regenerate via scenes/tools/bake_playground_navmesh.gd).
const PLAYGROUND_NAVMESH_PATH := "res://scenes/areas/playground_navmesh.tres"
# NavigationAgent3D behaviour on the companion.
## Must exceed the small residual vertical gap between the body and the navmesh above it.
const COMPANION_NAV_PATH_DESIRED_DISTANCE := 0.5
const COMPANION_NAV_TARGET_DESIRED_DISTANCE := 0.5
## How often the follow goal is pushed to the agent (s); the agent repaths internally as needed.
const COMPANION_NAV_GOAL_INTERVAL := 0.2
## How far behind the player the cat settles. THIS is the "stop distance" knob — raise for more space.
const COMPANION_STOP_DISTANCE := 1.7
## Never crowd closer than this to the player, even if the formation point lands in front of them.
const COMPANION_MIN_PLAYER_GAP := 0.7
## Movement speed ramps with distance to the player: gentle up close, faster catching up from far.
const COMPANION_FOLLOW_SPEED := 1.6
const COMPANION_CATCHUP_SPEED := 4.8
## Distance over which speed ramps from follow to catch-up (measured beyond the stop distance).
const COMPANION_CATCHUP_RANGE := 5.0
## Companions aim for a point behind the player, fanned out per companion with random jitter so
## multiple cats spread out rather than stacking on one point.
const COMPANION_FORMATION_ANGLE := 0.55
const COMPANION_FORMATION_JITTER_ANGLE := 0.28
const COMPANION_FORMATION_JITTER_DISTANCE := 0.5

# Companion brain — autonomous roam/idle + meow when settled near the player (see companion logic.md).
# Follow always wins: the cat drops roaming the moment the player moves or strays past the leash.
const COMPANION_BRAIN_ENABLED := true
## Beyond this distance to the player (or while the player moves) the cat follows instead of roaming.
const COMPANION_LEASH_SOFT := 3.5
## Orbit radius/angular speed when the cat circles the player.
const COMPANION_CIRCLE_RADIUS := 1.6
const COMPANION_CIRCLE_SPEED := 0.8
## Half-angle (radians) of the sector each cat wanders within, centred on its formation slot,
## so multiple cats roam and rest in different directions instead of clustering.
const COMPANION_WANDER_SECTOR := 0.9

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
