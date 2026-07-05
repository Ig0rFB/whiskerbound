# WHISKERBOUND — Project Brief & Architecture Document (3D / Godot)

> **Status**: M2 complete — **M3 companion follow** next  
> **Version**: 0.1.0  
> **Engine**: Godot 4.7 (Forward+)  
> **Language**: GDScript  
> **Authors**: Igor Barbosa (lead engineer), Yvonne Reinhardt (narrative & level design)  
> **Supersedes**: `whiskerbound-2d-prototype` (Odin/Raylib pixel-art V1 — design reference only)

---

## 1. Vision

Whiskerbound is an exploration-and-narrative-focused 3D adventure. The player controls a young protagonist (selectable girl/boy) accompanied by a cat companion named Lumi, journeying through a warm stylised world populated by cats, environmental puzzles, and branching story beats.

**Core experience**: walk, talk, explore, solve light environmental puzzles, collect cats, minimal combat. Puzzles and narrative carry the game — not grinding or combat mastery.

### Reference games (study these, do not clone)

| Reference | Take from it |
|---|---|
| **Order of the Sinking Star** (Thekla) | Isometric grid movement; puzzle readability; glowing interactables; biome variety; branching overworld |
| **Animal Crossing: New Horizons** | Soft rounded 3D forms; cosy scale; pastel lighting; toy-like props |
| **Pokémon (3D overworld — Sword/Shield towns, Legends Arceus fields)** | 3D character models on an implicit grid; fixed camera that follows the player; 8-direction locomotion |
| **The Legend of Zelda: The Wind Waker** | Expressive character animation; cel-adjacent warmth (long-term character target) |
| **Oceanhorn** | Island-based world structure; NPC and puzzle pacing |

### What this game is NOT

- Not voxel / Minecraft-style
- Not pixel art / 2D sprites
- Not first-person or free-orbit camera (V1)
- Not combat-heavy
- Not a general-purpose engine — use Godot as a game framework

### Relationship to 2D prototype

A completed Odin/Raylib prototype exists in `whiskerbound-2d-prototype`. Reuse its **design and algorithms**, not its code or art:

- Feet-only grid collision with wall sliding
- A* companion follow with repath and teleport fallback
- LDtk-style entity concepts (spawns, transitions, NPC markers) — reimplemented for 3D
- Event-driven system decoupling
- Milestone structure (movement → companion → dialogue → transitions → polish)

---

## 2. Art direction

### Style name

**Soft stylised isometric 3D** — rounded low-to-mid-poly geometry, hand-painted or flat material colours, warm lighting, readable silhouettes.

### Modelling rules

- **Rounded edges** on all props (bevel ≥ 15% on blockout shapes). No raw cubes except placeholder greybox.
- **Chibi/toy scale**: player ~0.8 units tall; doorways ~1.4 units; trees exaggerated and soft, not realistic.
- **Flat or subtle gradient textures** — no photoreal PBR. Matte clay / painted wood / soft grass.
- **Interactables glow**: pressure pads, portals, collectibles use emissive materials (pink, green, gold). Environment stays muted so puzzles read clearly (Order of the Sinking Star principle).
- **Placeholder art until final assets**: coloured `MeshInstance3D` primitives (capsule = player, sphere = companion, rounded boxes = props). No pixel art.

### Lighting

- **Outdoor**: bright directional sun, soft shadows, slight ambient sky colour (warm gold or cool teal depending on biome).
- **Interior / set-pieces**: volumetric fog optional; warm point lights in windows/lanterns; coloured light from stained glass acceptable.
- **Post-process (V1)**: subtle bloom on emissive objects; optional colour grade per biome. No heavy film grain.

### Colour palette (default biome)

- Ground: warm tan / moss green
- Stone: grey-lavender
- Wood: honey brown
- Accent (interactables): soft pink, mint green, gold
- Sky: pale blue with soft clouds

Biomes may override palette but must keep **interactable colours consistent** across the game.

---

## 3. Camera specification

### Mode

**Fixed-angle perspective camera** — NOT true orthographic. Perspective gives depth cues for cliffs, water, and character height while keeping an isometric *feel*.

This matches Pokémon 3D overworlds and Order of the Sinking Star: 3D models, locked camera angle, player cannot rotate the view in V1.

### Coordinate system (Godot default)

- **Y = up** (height)
- **Movement plane = XZ** (horizontal ground)
- **Logical "south"** = +Z (used for depth sorting and facing)
- **Logical "north"** = −Z

Map the 2D prototype convention (x, y tile coords) → 3D world (x, 0, z) where `z = tile_y`.

### Camera rig values (V1 defaults — tune in editor, document final values)

```
Camera3D (child of CameraRig node):

  Projection:     PERSPECTIVE
  FOV:            35–45° (lower = more isometric feel; start at 40°)

  Rig rotation (fixed, never changed by player input):
    Y rotation:   45°   (view from NE corner — classic isometric diagonal)
    X rotation:  −50°   (elevated, looking down at the play field)

  Rig offset from player target (local space, applied after rotation):
    Distance:     ~18–24 units from target (adjust until ~14 tiles fit vertically)
    Height bias:  target at player chest (Y ≈ 0.9 on a 0.8-tall character)

  Follow behaviour:
    Target:       player CharacterBody3D global_position (XZ) + chest height
    Smoothing:    lerp factor 8.0 * delta (same feel as 2D prototype)
    Snap:         instant reposition on area load or zoom change

  Clamp:
    Keep the view inside area bounds so the player never walks off-screen edge.
    Clamp rig target XZ so the viewport frustum stays inside the area AABB,
    with padding of half-viewport in world units.

  Zoom (optional V1 stretch):
    Not required for M1. If added later: adjust rig distance, not FOV.
    Re-anchor on zoom change (no sideways drift).

  Forbidden in V1:
    - Player camera rotation (mouse/right stick)
    - First-person
    - Over-the-shoulder
```

### Depth sorting (characters & props)

Sort draw order by **world Z** (south = in front):

```
render_priority or explicit sort: higher global_position.z → drawn later (on top)
```

Tie-break with Y if needed (elevated platforms). Static terrain uses normal 3D depth buffer; only billboarded/UI and character layers need explicit sort if z-fighting occurs.

### Screen / viewport

```
Fixed internal resolution:  1920 × 1080
Window:                     scalable with letterboxing (black bars)
Target FPS:                 60
```

---

## 4. Grid, movement & collision

### Grid

- **1 tile = 1 Godot unit (1 m)** on the XZ plane
- All gameplay logic operates on **continuous float positions** snapped for collision queries to a grid resolution of **1 unit** (configurable `GRID_CELL := 1.0`)
- Optional sub-grid of 0.25 for fine collision painting later; start with 1.0

### Player movement

```
Speed:              4.5 units/sec (match 2D prototype feel)
Input:              8-direction (WASD / left stick), normalised diagonals
Facing:             8 compass directions derived from velocity (same octant logic as 2D prototype)
Animation:          blend or snap to 8-dir idle/walk (placeholder: rotate model to face velocity)
Collision body:     CharacterBody3D with CapsuleShape3D (radius 0.25, height 0.7)
Collision mode:     move_and_slide on XZ; Y locked to ground height (no jumping V1)
Wall slide:         separate axis resolution (move X, then Z) — port 2D prototype logic
```

### Feet-only collision sampling

Port directly from 2D prototype:

- Collider is **feet-centred** on the ground plane
- Collision queries sample the **IntGrid / collision map at foot points** (bottom of capsule), not the entity centre
- Apply `COLLISION_INSET` (default 0.1 units) to reduce edge snagging on narrow paths

### Collision map

- Each area stores a 2D `width × height` grid of solid/walkable flags
- Stored as resource (`AreaCollisionGrid`) or baked from Godot `GridMap` / painted mesh
- Height: single ground plane per area for V1; cliffs are visual mesh with collision blocking at cliff edges (grid cell marked solid)

### Ground height (V1)

- Flat Y = 0 per area unless explicit `HeightZone` volumes set Y (stretch goal M6+)
- Character Y snapped to ground height each frame

---

## 5. Technology stack

| Layer | Choice |
|---|---|
| Engine | Godot 4.3+ |
| Language | GDScript |
| Version control | Git, GitHub repo `whiskerbound` |
| Primary platform | macOS Apple Silicon |
| Secondary | Windows, Linux (Godot export) |
| Level authoring | Godot Editor scenes (primary); optional LDtk for grid/entity metadata import |
| 3D assets (placeholder) | Godot primitives; later Blender (rounded low-poly) |
| Audio | Godot AudioStreamPlayer / OGG + WAV |
| CI | GitHub Actions — `godot --headless --quit` sanity check when test suite exists |

### Why Godot

Full engine (3D, UI, audio, pathfinding, export). Isometric 3D is a known pattern. Open-source. Good macOS support.

---

## 6. Architecture principles

### 6.1 Strict layer separation

Dependencies flow downward only:

```
input/          → reads hardware, produces abstract actions
core/           → pure game logic; NO extends Node; NO draw calls
scenes/         → Godot nodes, meshes, animation; calls core systems
ui/             → Control nodes; UI logic separate from layout where practical
```

**Rule**: `core/` scripts are plain GDScript classes (`class_name` optional). If a file in `core/` extends `Node`, refactor.

### 6.2 Data-oriented state

Central `GameState` autoload holds world state as plain data:

```gdscript
# autoloads/game_state.gd
var mode: GameMode = GameMode.GAMEPLAY
var world: WorldData
var entities: EntityStore      # parallel arrays or typed dictionaries
var player_entity_id: int = -1
var companion_ids: Array[int] = []
var camera_rig_state: CameraState
var quest_flags: Dictionary = {}
var current_area_id: String = ""
# ...
```

Start with parallel arrays (match 2D prototype SoA). Do not over-engineer ECS.

### 6.3 Event-driven decoupling

```gdscript
# autoloads/events.gd
signal player_interacted(source_id: int, target_id: int)
signal dialogue_started(npc_id: int)
signal dialogue_ended
signal item_collected(item_id: String)
signal puzzle_solved(puzzle_id: String)
signal area_entered(area_id: String)
signal cat_found(cat_id: String)
signal combat_hit(attacker_id: int, target_id: int)
```

Systems emit signals; listeners connect in `_ready` or bootstrap. Flush transient events at end of frame if using a queue pattern.

### 6.4 Configuration as data

All tunables in `config.gd` autoload or `config.gd` constants file:

```gdscript
const GRID_CELL := 1.0
const PLAYER_SPEED := 4.5
const COMPANION_FOLLOW_DISTANCE := 3.0
const INTERACT_RADIUS := 1.5
const VIEWPORT_WIDTH := 1920
const VIEWPORT_HEIGHT := 1080
const TARGET_FPS := 60
const COLLISION_INSET := 0.1
const CAMERA_FOLLOW_SPEED := 8.0
```

---

## 7. Project structure

```
whiskerbound/
├── project.godot
├── config.gd                    # constants
├── autoloads/
│   ├── game_state.gd
│   ├── events.gd
│   └── scene_flow.gd            # area transitions, fade
├── core/
│   ├── types.gd                 # Vec2 (xz), Rect, Direction8, enums
│   ├── world.gd                 # collision grid, spatial queries
│   ├── entity_store.gd
│   ├── movement.gd              # velocity, wall slide, facing
│   ├── pathfinding.gd           # AStarGrid2D wrapper (XZ plane)
│   ├── companion.gd
│   ├── interaction.gd
│   ├── puzzle.gd
│   ├── transition.gd
│   ├── dialogue_data.gd
│   ├── combat.gd                # minimal V1
│   └── systems/
│       ├── movement_system.gd
│       ├── companion_system.gd
│       ├── interaction_system.gd
│       ├── puzzle_system.gd
│       ├── transition_system.gd
│       ├── animation_system.gd
│       └── combat_system.gd
├── input/
│   └── input_actions.gd         # maps InputMap → Action enum
├── scenes/
│   ├── main.tscn
│   ├── camera/
│   │   └── camera_rig.tscn      # Camera3D with fixed rotation
│   ├── player/
│   │   └── player.tscn          # CharacterBody3D + placeholder mesh
│   ├── companion/
│   │   └── companion.tscn
│   ├── npc/
│   │   └── npc.tscn
│   └── areas/
│       ├── area_base.tscn       # template: ground, collision, spawn markers
│       ├── village_green.tscn   # first playable area
│       └── forest_path.tscn     # second area (transitions)
├── ui/
│   ├── hud.tscn
│   ├── dialogue_box.tscn
│   ├── pause_menu.tscn
│   └── minimap.tscn
├── assets/
│   ├── materials/               # toon/flat placeholder materials
│   ├── audio/
│   └── fonts/
├── data/
│   ├── dialogue/                # JSON or .gd dictionaries
│   └── areas/                   # collision grid exports if not baked in scenes
└── .github/workflows/ci.yml
```

---

## 8. Game loop

```gdscript
# scenes/main.gd (_process / _physics_process)

func _physics_process(delta: float) -> void:
    InputActions.poll()

    TransitionSystem.update(delta)

    match GameState.mode:
        GameMode.GAMEPLAY:
            MovementSystem.update(delta)
            CompanionSystem.update(delta)
            InteractionSystem.update()
            PuzzleSystem.update()
            CombatSystem.update(delta)
            AnimationSystem.update(delta)
        GameMode.DIALOGUE:
            DialogueSystem.update()
        GameMode.PAUSE, GameMode.MENU, GameMode.INVENTORY:
            pass  # UI handles input

    UISystem.update(delta)
    # events queue flush if used

func _process(delta: float) -> void:
    CameraRig.follow_player(delta)
    # render is automatic via scene tree
```

---

## 9. Core systems (behaviour spec)

### 9.1 Player

- Spawn at `PlayerSpawn` marker in current area
- `CharacterBody3D`, placeholder capsule mesh (distinct colour, e.g. coral)
- 8-dir movement with wall slide
- Feet-only collision
- Facing drives placeholder rotation or animation blend

### 9.2 Cat companion (Lumi)

- Follows player via **A* on collision grid** (Godot `AStarGrid2D` on XZ)
- Stops within `COMPANION_FOLLOW_DISTANCE` (~3 units)
- Repath every 0.5 s or when player moves >2 units
- **Stuck detection**: if no progress for 2 s, teleport to nearest walkable cell beside player
- Does not block player movement (companion on its own collision layer or smaller capsule)
- Placeholder: small sphere mesh (cream colour)
- Idle behaviour: occasional pause + look-around (timer-based, M3+)

### 9.3 NPC interaction

- NPCs placed as scene markers with fields: `npc_id`, `dialogue_id`, `display_name`
- Interact when player within `INTERACT_RADIUS` and presses Interact action
- Opens dialogue UI; pauses gameplay input
- Advance line / dismiss with Confirm / Cancel
- Face player toward NPC when dialogue opens (rotate model on Y axis)

### 9.4 Dialogue

- Hardcoded or JSON keyed by `dialogue_id` for V1
- Include speaker name + portrait placeholder (coloured rect)
- First NPC: **Elder Cat** — reuse lines from 2D prototype as starting content

### 9.5 Area transitions

- `TransitionZone` Area3D markers: `target_area_id`, `target_spawn_name`
- On enter: fade out (0.4 s) → load area → reposition player + companions → fade in
- Companions persist across transitions
- Bidirectional exits required between first two areas

### 9.6 Environmental puzzles (M7)

- Pressure plates, switches, doors — state tracked in `GameState.quest_flags`
- Plate activated when player or pushable object within radius
- Doors: animated slide/rotate; blocked by collision when closed
- Interactables use **emissive glow** material when active

### 9.7 Combat (M9 — minimal)

- Basic melee, dodge roll, simple enemy telegraph
- Keep simple; puzzles and narrative are primary

### 9.8 Cat collection (M8)

- Findable cat entities in areas
- Collection triggers narrative beat + journal entry
- Persists across transitions and save/load

---

## 10. Area authoring workflow

### V1 approach (Godot Editor)

Each area is a `.tscn` with:

- `Ground` — MeshInstance3D or GridMap (placeholder green/brown material)
- `CollisionGrid` — Node exporting a baked `PackedByteArray` or resource, OR StaticBody3D walls outlining unwalkable regions
- Marker nodes:
  - `PlayerSpawn`
  - `NamedSpawn` (name property)
  - `TransitionZone` (Area3D + export vars)
  - `NPCSpawn` (npc_id, dialogue_id)
  - `CatSpawn` (cat_id)
  - `PuzzleElement` (plate, door, switch)

Yvonne (designer) places markers in Godot Editor. No LDtk required for M1–M6.

### Optional later: LDtk import

Import 2D grid + entity layer as XZ collision and marker positions (reuse design from 2D prototype maps as reference geometry, not art).

---

## 11. Input

Define in Project → Input Map:

| Action | Keyboard | Gamepad |
|---|---|---|
| move_up | W / Up | Left stick up |
| move_down | S / Down | Left stick down |
| move_left | A / Left | Left stick left |
| move_right | D / Right | Left stick right |
| interact | E / Space | A button |
| attack | (M9) | X button |
| dodge | (M9) | B button |
| pause | Escape | Start |
| toggle_minimap | M | Select |

`input/input_actions.gd` converts to `Action` enum with `held`, `pressed`, `released` each frame.

---

## 12. UI

- **Dialogue box**: bottom third, speaker name, portrait placeholder, line text
- **HUD**: minimal — interact prompt when in range ("Press E")
- **Minimap**: top-right, 2D overhead of area collision grid + player dot (toggle M)
- **Pause menu**: resume, quit
- **Debug HUD** (M6): FPS, collision overlay toggle (H), entity picker (stretch)

All UI in `CanvasLayer`. UI logic scripts must not manipulate 3D scene directly.

---

## 13. Milestone roadmap

Build in order. Each milestone = playable build.

### M1: Window + 3D area + camera

- [x] Godot project opens on macOS
- [x] `village_green.tscn` loads with placeholder ground mesh
- [x] Camera rig: fixed isometric angle, follows player
- [x] 1920×1080 viewport with letterboxing
- [x] Player spawns at PlayerSpawn marker

### M2: Grid movement + collision

- [x] 8-direction movement on XZ plane
- [x] Collision grid blocks movement; wall sliding works
- [x] Feet-only sampling + collision inset
- [x] Debug overlay: draw collision grid (H toggle)

### M3: Companion

- [ ] Lumi follows via AStarGrid2D
- [ ] Stop distance, repath, stuck teleport fallback
- [ ] Depth sort by Z (companion draws in front/behind correctly)

### M4: NPC + dialogue

- [ ] Elder Cat NPC in village area
- [ ] Interact → dialogue box with 3 hardcoded lines
- [ ] Advance / dismiss; gameplay input blocked during dialogue

### M5: Area transitions

- [ ] Second area `forest_path.tscn`
- [ ] TransitionZone triggers fade + load + spawn at NamedSpawn
- [ ] Bidirectional travel; companion persists

### M6: Mechanics polish

- [ ] Walk all paths without snagging (manual checklist)
- [ ] Camera clamp at area edges
- [ ] Interact prompt UI
- [ ] Player faces NPC on talk
- [ ] Minimap with player dot
- [ ] Fade timing tuned

**M6 exit criteria**: spawn → explore village → transition to forest → return; talk to Elder Cat; companion follows throughout; no collision snags.

### Deferred (after M6)

- **M7**: Environmental puzzles (plates, doors, switches)
- **M8**: Cat collection + journal UI
- **M9**: Minimal combat
- **M10**: Save/load + audio polish + particles

---

## 14. Placeholder asset spec (until real art)

| Entity | Placeholder | Colour |
|---|---|---|
| Player | CapsuleMesh 0.25r × 0.7h | Coral `#E8847A` |
| Lumi (companion) | SphereMesh r=0.2 | Cream `#F5E6C8` |
| NPC cat | BoxMesh rounded 0.5³ | Grey-lavender `#9B8FA8` |
| Ground | PlaneMesh or BoxMesh 1×0.1×1 tiles | Moss `#7CB87C` |
| Wall / blocker | BoxMesh | Stone `#8A8490` |
| Transition zone | transparent BoxMesh (visible in debug) | Cyan wireframe |
| Pressure plate | CylinderMesh r=0.4, emissive when active | Pink `#FF88CC` |
| Tree (decoration) | Sphere + cylinder stack | Green `#5A9E5A` |

Materials: `StandardMaterial3D` with `shading_mode = SHADING_MODE_UNSHADED` or mild toon; `roughness = 0.9`; no normal maps in placeholder phase.

---

## 15. Agent implementation notes

1. **Read this entire document before writing code.**
2. **Implement milestones in order** — M2 is complete; next is **M3** (companion follow).
3. **Keep `core/` free of Node dependencies** — test movement and collision as plain GDScript unit tests where possible (`GdUnit4` optional).
4. **Match 2D prototype feel** for movement speed, camera follow smoothing, and companion behaviour — reference `whiskerbound-2d-prototype` if needed.
5. **Camera angle is fixed** — rig values live in `config.gd` (`CAMERA_YAW`, `CAMERA_PITCH`, `CAMERA_FOV`, `CAMERA_DISTANCE`).
6. **No pixel art, no voxels, no free camera in V1.**
7. **After each milestone**: update this file (checklist + status), `README.md`, and `AGENTS.md` if workflow changed; run `bash scripts/run_smoke_test.sh`; commit and push.
8. **Commit message format**: `M1: window + 3D area + camera rig`
9. **British spelling** in comments and user-facing strings.
10. Target: Godot 4.3+, macOS Apple Silicon, 60 FPS on placeholder assets.

### Verification (M1)

Headless smoke test (no display required):

```bash
bash scripts/run_smoke_test.sh
# Expected: SMOKE_OK: player at (10.0, 0.0, 8.0) area=village_green
```

Interactive: open project in Godot 4.7 and press **F5**. WASD to walk; **H** toggles collision overlay.

### Verification (M2)

Smoke test covers open movement, edge blocking, and solid tree cells:

```bash
bash scripts/run_smoke_test.sh
# Expected: SMOKE_OK: player at (10.0, 0.0, 8.0) area=village_green
```

---

## 16. Authors & roles

- **Igor**: engineering, architecture, camera tuning, systems
- **Yvonne**: level layout in Godot Editor, narrative, NPC dialogue content, pacing
