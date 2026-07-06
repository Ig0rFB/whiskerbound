# WHISKERBOUND — Project Brief & Architecture Document (3D / Godot)

> **Status**: M5 next (area transitions — see §13). **M3 companion autonomy** in progress (idle wander, activities, meows). M6 items landed early: TPC playground, unified debug HUD, grounded actors.  
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
| **Kena: Bridge of Spirits** | Warm stylised 3D; readable traversal on varied terrain; companion as emotional anchor; gentle combat pacing |
| **Pokémon Legends: Arceus** | Open-field 3D exploration; rolling hills and platforms; character grounded on uneven ground; approachable scale |
| **Pokémon (Sword/Shield towns, Scarlet/Violet overworld)** | 3D character on implicit grid; camera follows player; town/field readability |
| **The Legend of Zelda: Breath of the Wild / Tears of the Kingdom** | 3D traversal on slopes and ledges; physics-grounded movement; environmental puzzle readability |
| **The Legend of Zelda: The Wind Waker** | Expressive character animation; cel-adjacent warmth (long-term character target) |
| **Order of the Sinking Star** (Thekla) | Puzzle readability; glowing interactables; biome variety; branching overworld |
| **Animal Crossing: New Horizons** | Soft rounded 3D forms; cosy scale; pastel lighting; toy-like props |
| **Oceanhorn** | Island-based world structure; NPC and puzzle pacing |

### What this game is NOT

- Not voxel / Minecraft-style
- Not pixel art / 2D sprites
- Not first-person or free-orbit camera beyond the Jeheno TPC spring arm
- Not combat-heavy
- Not a general-purpose engine — use Godot as a game framework

### Relationship to 2D prototype

A completed Odin/Raylib prototype exists in `whiskerbound-2d-prototype`. Reuse its **design and algorithms where they still fit**, not its code or art:

| From 2D prototype | Status in 3D |
|---|---|
| A* companion follow, repath, stuck teleport | **Active** — `core/companion/`, `AStarGrid2D` on XZ |
| LDtk-style entity concepts (spawns, transitions, NPC markers) | **Active** — reimplemented as Godot markers |
| Event-driven decoupling, milestone structure | **Active** |
| Feet-only grid collision + wall sliding for **player** | **Replaced** — player uses Jeheno TPC `CharacterBody3D` physics (§4) |
| 2D collision map as sole world collision | **Partial** — logic grid remains for companion pathfinding, minimap, debug; world blocking is 3D physics |

---

## 2. Art direction



### Lighting

- **Outdoor**: bright directional sun, soft shadows, slight ambient sky colour (warm gold or cool teal depending on biome).
- **Interior / set-pieces**: volumetric fog optional; warm point lights in windows/lanterns; coloured light from stained glass acceptable.
- **Post-process (V1)**: subtle bloom on emissive objects; optional colour grade per biome. No heavy film grain.

### Colour palette (default biome)


---

## 3. Camera specification

### Mode (gameplay — M6)

**Third-person spring-arm camera** via Jeheno TPC addon (`CameraHolder` + `SpringArm3D`). The player orbits the camera with mouse / right stick; scroll wheel, V/B keys, and **L2/R2** triggers adjust zoom.

Legacy **fixed-angle OOTS-style rig** (`scenes/camera/camera_rig.tscn`) remains for editor preview only — not used during gameplay.

### Coordinate system (Godot default)

- **Y = up** (height)
- **Movement plane = XZ** (horizontal ground)
- **Logical "south"** = +Z (used for depth sorting and facing)
- **Logical "north"** = −Z

Map the 2D prototype convention (x, y tile coords) → 3D world (x, 0, z) where `z = tile_y`.

### Grounded actors (M6 default)

All companions and NPCs extend `core/world/grounded_character.gd` (`CharacterBody3D`):

- Capsule collision aligned to feet (`Config.CHARACTER_*` / `COMPANION_*` / `NPC_*`)
- Gravity + `move_and_slide()` + floor snap (same principle as the TPC player)
- Collision layer **2** (characters), mask **1** (world CSG/mesh)
- Player TPC also masks layer 2 so NPCs block movement

New spawned characters should inherit this base unless a scene overrides body size. **Full implementation guide: §9.0.**

### Legacy OOTS camera rig (editor only)

```
Camera3D (child of CameraRig node):

  Projection:     PERSPECTIVE
  FOV:            35–45° (lower = more isometric feel; start at 40°)

  Rig rotation (fixed, never changed by player input):
    Y rotation:   0°    (axis-aligned — camera south, looking north; NOT 45° diagonal)
    X rotation:  −42°   (elevated oblique — OOTS / Pokémon overworld feel)

  Rig offset from player target (local space, applied after rotation):
    Distance:     ~18 units from target (adjust until ~14 tiles fit vertically)
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

Whiskerbound uses a **dual-layer collision model**: 3D physics for actors against real geometry, and a 2D logic grid for companion AI, minimap, and debug overlays.

### Layer 1 — 3D world physics (primary)

**Who uses it:** player, companions, NPCs, static level geometry (CSG, `StaticBody3D`, mesh colliders).

**Physics layers** (`config.gd`):

| Layer | Bit | Contents |
|---|---|---|
| World | 1 | Playground CSG, static meshes, terrain |
| Character | 2 | Player, companions, NPCs |

**Player — Jeheno third-person controller** (`addons/JehenoThirdPersonController/`, adapted via `scenes/player/tpc_player.gd`):

- Root: `CharacterBody3D` with capsule collider (~radius 0.35, height ~1.7 — tuned in addon scene)
- **Gravity:** separate jump and fall curves (`jump_gravity`, `fall_gravity`) applied when not on floor
- **Movement:** state machine (idle / walk / run / jump / in-air) sets horizontal velocity; `move_and_slide()` each physics frame
- **Floor detection:** `is_on_floor()`, `floor_snap_length` (1.0 on ground states, 0 in jump), coyote-time jump buffer
- **Walls:** optional velocity cut on wall hit (`hit_wall_cut_velocity`); spring-arm camera collision against layer 1
- **Whiskerbound adapter:** exposes `feet_velocity` for companion AI; masks layers 1 **and** 2 so NPCs block the player; disables addon HUD; handles wheel/L2/R2 zoom

This is the reference implementation for “good” 3D collision — companions and NPCs mirror its pattern via `GroundedCharacter` (§9.0), not via grid sampling.

**Companions & NPCs — `GroundedCharacter`:**

- Same engine primitives: `CharacterBody3D`, capsule, `apply_gravity()`, `move_and_slide()`, `snap_to_floor()`
- Companions: horizontal velocity from A* follow; Y from physics
- NPCs: static XZ, gravity keeps them on slopes/platforms

**Level geometry:** Jeheno playground map (`Map/test_map_scene.tscn`) uses CSG with collision on layer 1. New areas should follow the same rule: world colliders on layer 1, characters on layer 2.

### Layer 2 — Logic grid (companion AI & overlays)

**Who uses it:** companion pathfinding, minimap walkability tint, collision debug overlay, smoke tests. **Not** the player's primary collision in the TPC playground.

**Implementation:** `core/world/collision_grid.gd` — 2D `width × height` solid/walkable flags on the XZ plane (`GRID_CELL := 1.0`).

| Area | Grid source | Notes |
|---|---|---|
| `playground` | Coarse baked grid (112×112): borders + one marker solid cell | Does **not** mirror CSG walls — companion may path through grid cells the player cannot walk through |
| `village_green` | Full painted grid (legacy flat area) | Matches old 2D-style feet sampling; kept for regression |

**Feet sampling** (`core/movement/movement.gd`, `player_collider.gd`, `COLLISION_INSET`): still used for grid-based logic and the legacy village area. Rect footprint at foot height, inset 0.1 units to reduce edge snagging.

**Future (post-M5):** bake or paint the logic grid from 3D geometry (navmesh slice, CSG export, or designer-painted overlay) so companion paths respect the same obstacles the player hits. Until then, accept that A* is approximate in the playground.

### Grid & coordinates

- **1 tile = 1 Godot unit (1 m)** on the XZ plane
- Gameplay uses **continuous float positions**; grid cells are for queries and pathfinding
- Map 2D prototype tile `(x, y)` → 3D world `(x, y_height, z)` where `z = tile_y`

### Player movement (summary)

| Aspect | Implementation |
|---|---|
| Input | WASD / left stick via Jeheno input actions; run (Shift/Y), jump (Space/A) |
| Speed | Walk ~5 u/s, run ~9 u/s (addon defaults); `Config.PLAYER_SPEED` used for companion prediction |
| Facing | Model rotates toward move direction or camera (aim mode) |
| Vertical | Full jump arc — not Y-locked |
| Collision | 3D capsule + `move_and_slide()` — not grid wall-slide |

---

## 5. Technology stack

| Layer | Choice |
|---|---|
| Engine | Godot 4.7 (Forward+) |
| Language | GDScript |
| Version control | Git, GitHub repo `whiskerbound` |
| Primary platform | macOS Apple Silicon |
| Secondary | Windows, Linux (Godot export) |
| Level authoring | Godot Editor scenes (primary); optional LDtk for grid/entity metadata import |
| 3D assets (placeholder) | Godot primitives; later Blender (rounded low-poly) |
| Audio | Godot AudioStreamPlayer / OGG + WAV |
| CI | GitHub Actions — `godot --headless --quit` sanity check when test suite exists |

### Why Godot

Full engine (3D, UI, audio, pathfinding, export). Third-person 3D with `CharacterBody3D` is a first-class pattern. Open-source. Good macOS support.

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

**Rule**: `core/` scripts must be engine-light and testable:

- **No autoload references** (`GameState`, `Events`, `Config` values passed in as parameters or set via injection, never looked up)
- **No scene-tree lookups** (`get_node`, `$Path`, groups) outside a script's own children
- **No `res://` paths to scenes** — scene loading belongs in `scenes/` and `autoloads/`
- Pure-logic scripts (movement, pathfinding, collision grid maths) must not extend `Node` at all, so they can be unit-tested headlessly

**Documented exception**: reusable Node base classes live in `core/world/` when multiple scene families extend them. Currently only `grounded_character.gd` (`CharacterBody3D` base for companions and NPCs, §9.0). Adding another Node base class to `core/` requires a note here justifying it.

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
const COMPANION_FOLLOW_DISTANCE := 1.25
const INTERACT_RADIUS := 1.5
const COLLISION_INSET := 0.1
const COLLISION_LAYER_WORLD := 1
const COLLISION_LAYER_CHARACTER := 2
const CHARACTER_BODY_RADIUS := 0.25
const VIEWPORT_WIDTH := 2560
const VIEWPORT_HEIGHT := 1440
const TARGET_FPS := 60
```

---

## 7. Project structure

```
whiskerbound/
├── project.godot
├── config.gd                    # global tunables: physics layers, speeds, colours
├── PROJECT.md / README.md / AGENTS.md
├── autoloads/
│   ├── game_state.gd            # world refs, mode, companions, NPCs
│   ├── game_settings.gd         # resolution, minimap size (persisted)
│   └── events.gd                # global signals
├── core/                        # logic layer — see §6.1 rules
│   ├── types.gd                 # Direction8, shared enums
│   ├── camera/                  # camera_debug_info.gd
│   ├── companion/               # companion_logic, companion_idle_logic, companion_data, …
│   ├── dialogue/                # dialogue_data.gd
│   ├── interaction/             # interaction.gd
│   ├── movement/                # movement.gd, player_collider.gd
│   ├── pathfinding/             # pathfinding.gd (AStarGrid2D on XZ)
│   ├── render/                  # depth_sort.gd
│   ├── save/                    # save_game.gd
│   ├── ui/                      # minimap_logic.gd
│   └── world/                   # collision_grid.gd, grounded_character.gd (§9.0)
├── input/
│   ├── input_actions.gd         # keyboard + gamepad → actions each frame
│   └── gamepad.gd               # deadzone, confirm/cancel layout, L2/R2 zoom
├── scenes/
│   ├── main.tscn / main.gd / area_manager.gd
│   ├── areas/                   # playground (default), village_green (legacy grid)
│   ├── camera/                  # camera_rig (legacy OOTS, editor only), camera_preview
│   ├── companion/               # companion.gd/.tscn
│   ├── debug/                   # collision_debug, companion_path_debug
│   ├── npc/                     # npc.gd/.tscn
│   ├── player/                  # player.tscn (Jeheno TPC instance), tpc_player.gd
│   └── tools/                   # smoke_test, companion_visual_test, tpc_sandbox
├── ui/
│   ├── game_ui.tscn/.gd         # orchestrates HUD, pause, dialogue
│   ├── debug_hud.gd             # unified debug overlay (H)
│   ├── minimap.gd
│   ├── pause_menu.gd/.tscn
│   ├── dialogue_box.gd/.tscn
│   ├── interact_prompt.gd/.tscn
│   └── companion_bark.gd/.tscn  # meow speech bubble
├── scripts/                     # run_smoke_test.sh, run_companion_visual_test.sh, tpc sandbox runners
├── assets/                      # audio, fonts, materials, models (cat.glb, adventurer GLBs)
├── addons/                      # JehenoThirdPersonController, anthonyec.camera_preview
└── reference/                   # local clone of whiskerbound-2d-prototype (not in git)
```

Planned but not yet created: `data/` (dialogue and area resources once content outgrows hardcoding), `scenes/areas/forest_path.tscn` (M5), `.github/workflows/ci.yml`. Add them when the milestone demands, not before.

---

## 8. Game loop

**Current model (as implemented)**: updates are distributed across scene scripts, gated by `GameState.mode`:

- `input/input_actions.gd` polls hardware into abstract actions each frame
- `scenes/player/tpc_player.gd` handles player physics via the Jeheno state machine
- `scenes/companion/companion.gd` and `scenes/npc/npc.gd` run their own `_physics_process`, delegating decisions to `core/companion/companion_logic.gd` etc.
- `ui/game_ui.gd` orchestrates HUD, pause, and dialogue
- Mode gating: gameplay scripts early-return unless `GameState.mode == GameMode.GAMEPLAY`; dialogue and pause suppress movement input

**Rules that keep this manageable**:

1. Every gameplay `_physics_process` checks `GameState.mode` first (or is gated by its parent). No script may move an actor during `DIALOGUE` or `PAUSE`.
2. Decision logic lives in `core/`; scene scripts translate decisions into `velocity`, `move_and_slide()`, and animation.
3. Cross-system communication goes through `Events` signals, never direct node references between unrelated scenes.

A central system dispatcher (MovementSystem, CompanionSystem, ...) was the original plan and may return if per-scene updates become hard to reason about, but do not migrate speculatively.

---

## 9. Core systems (behaviour spec)

### 9.0 GroundedCharacter (base class)

**File:** `core/world/grounded_character.gd` (`class_name GroundedCharacter`)

Default `CharacterBody3D` for any actor that should stand on 3D world geometry (CSG, static meshes), fall with gravity, and block or be blocked by the environment. Companions and NPCs extend this; the **player** uses the Jeheno TPC controller (`CharacterBody3D` with its own capsule) but follows the same physics idea: `move_and_slide()`, `is_on_floor()`, floor snap.

#### What the base provides

| Behaviour | Detail |
|---|---|
| Collision | Auto-created or updated `CapsuleShape3D` on `CollisionShape3D`, centred at half `body_height` |
| Layers | Layer **2** (`Config.COLLISION_LAYER_CHARACTER`), mask **1** (`Config.COLLISION_LAYER_WORLD`) |
| Motion | `MOTION_MODE_GROUNDED`, `floor_snap_length = 0.5`, rotation locked on X/Y/Z |
| Spawn | `snap_to_floor()` deferred from `_ready()` — pushes down until `is_on_floor()` |
| Per frame | Subclasses call `apply_gravity(delta)` then `move_and_slide()` |

#### Config tunables (`config.gd`)

| Constant | Default | Use |
|---|---|---|
| `CHARACTER_BODY_RADIUS` / `CHARACTER_BODY_HEIGHT` | 0.25 / 0.7 | Generic fallback on the base class |
| `COMPANION_BODY_RADIUS` / `COMPANION_BODY_HEIGHT` | 0.22 / 0.35 | Lumi and other companions |
| `NPC_BODY_RADIUS` / `NPC_BODY_HEIGHT` | 0.25 / 0.7 | Elder Cat and other NPCs |

Override `body_radius` and `body_height` **before** `super._ready()` when the model needs a different footprint.

#### Scene template

```
MyActor (CharacterBody3D)          ← script extends grounded_character.gd
├── CollisionShape3D               ← optional; base creates one if missing
└── Visual (Node3D or MeshInstance3D)   ← art only; Y offset = body_height * 0.5 for centred meshes
```

- Root transform **feet at origin**: place the node at `(x, y, z)` where `y` is eventually resolved by physics (spawn high, `snap_to_floor()` finds the floor).
- Do **not** put gameplay logic on `Visual` — collision lives on the root body.
- World geometry must be on collision **layer 1**.

#### Script template

```gdscript
extends "res://core/world/grounded_character.gd"

@onready var _visual: Node3D = $Visual


func _ready() -> void:
    body_radius = Config.NPC_BODY_RADIUS   # or COMPANION_* / custom
    body_height = Config.NPC_BODY_HEIGHT
    super._ready()


func _physics_process(delta: float) -> void:
    # 1. Set velocity.x / velocity.z from your AI or input (XZ plane)
    # 2. Always:
    apply_gravity(delta)
    move_and_slide()
```

#### Reference implementations

| Actor | Pattern | File |
|---|---|---|
| **Moving** (companion) | A* sets target feet on XZ → `_apply_horizontal_velocity()` → `apply_gravity()` → `move_and_slide()` | `scenes/companion/companion.gd` |
| **Static** (NPC) | `velocity.x/z = 0` each frame → `apply_gravity()` → `move_and_slide()` (stays on slopes/platforms) | `scenes/npc/npc.gd` |

**Spawn from code** (e.g. `area_manager.gd`):

```gdscript
var actor := preload("res://scenes/companion/companion.tscn").instantiate()
_world_root.add_child(actor)
actor.global_position = Vector3(feet_x, 0.0, feet_z)
actor.call_deferred("snap_to_floor")   # or actor.setup(slot, feet) for companions
```

#### Checklist — new grounded actor

1. Create `.tscn` with root type **CharacterBody3D** (not `Node3D`).
2. Script `extends "res://core/world/grounded_character.gd"`.
3. Set `body_radius` / `body_height` in `_ready()` before `super._ready()`.
4. Add a `Visual` child for meshes; align art so feet sit at the root origin.
5. In `_physics_process`: set horizontal velocity (if any), then `apply_gravity(delta)` and `move_and_slide()`.
6. On programmatic spawn: set XZ position, then `call_deferred("snap_to_floor")`.
7. Register with game systems as needed (`add_to_group("npcs")`, `GameState.companions`, etc.).
8. Player must mask layer 2 to collide with NPCs — already set in `scenes/player/tpc_player.gd`.

#### Do not

- Set `global_position.y` from raycasts each frame — use physics instead.
- Use `Node3D` roots for characters that should block the player or stand on ramps.
- Put collision shapes only on a child visual — the capsule must be on the `CharacterBody3D` root.

---

### 9.1 Player

- Spawn at `PlayerSpawn` marker in current area
- **Jeheno third-person controller** — scene: `addons/.../player_character_scene.tscn`, adapter: `scenes/player/tpc_player.gd`
- **Physics (from addon, do not reimplement):**
  - `CharacterBody3D` + capsule on layer 2
  - State machine: idle, walk, run, jump, in-air — each applies gravity and calls `move_and_slide()`
  - Jump: configurable height/time-to-peak; coyote time; air jumps; jump buffer
  - Ground states set `floor_snap_length = 1.0` so the body sticks to ramps and platforms
  - Debug HUD reads `is_on_floor()`, state name, air jumps — use these when tuning levels
- **Whiskerbound hooks:** `feet_velocity` (XZ) for companion AI; collision mask includes layer 2 (NPCs); spring-arm camera bound to `GameState.camera_rig`; addon HUD hidden
- **Do not** port 2D grid wall-slide to the player — extend the Jeheno controller or adjust capsule/spring arm instead

### 9.2 Cat companion (Lumi)

- Extends **GroundedCharacter** (§9.0) — `CharacterBody3D` + capsule, gravity, floor snap
- Follows player via **A* on collision grid** (Godot `AStarGrid2D` on XZ)
- Stops within `COMPANION_FOLLOW_DISTANCE`
- Repath every `COMPANION_REPATH_INTERVAL` s; stuck teleport fallback after `COMPANION_STUCK_SECONDS`
- Horizontal motion from `CompanionLogic`; vertical motion from physics (not manual Y raycasts)
- `cat.glb` mesh under `Visual/Model`; editor floor snap via raycast (place X/Z only in area scenes)

**Follow vs autonomous (M3 extension — in progress)**

| Mode | When | Logic |
|---|---|---|
| **Follow** | Player moving, or companion far from player | `CompanionLogic` — A* toward predicted player feet |
| **Autonomous** | Player idle ≥ `COMPANION_IDLE_ENTER_SECONDS` and companion within wander radius | `CompanionIdleLogic` — wander, sit, play, groom |

Autonomous activities (timer-based state machine in `core/companion/`):

- **Wander** — random clear cell near player (`COMPANION_WANDER_RADIUS`), A* path
- **Sit / play / groom** — hold position; play named clip when present in `cat.glb`
- **Meow** — random interval (`COMPANION_MEOW_*`); `Events.companion_barked` → speech bubble (`ui/companion_bark.tscn`)

Animation names are tunables in `config.gd` (`COMPANION_ANIM_SIT`, etc.). Only `walk` exists in the GLB today; idle clips are placeholders until art lands.

**Scene wiring:** `scenes/companion/companion.gd` reads player `feet_velocity`, delegates to core logic, drives `AnimationPlayer`, emits barks. UI listens via `Events` — no scene-tree lookups from `core/`.

### 9.3 NPC interaction

- NPCs extend **GroundedCharacter** (§9.0) — static capsule blocks player
- Scene markers with fields: `npc_id`, `dialogue_id`, `display_name`
- Interact when player within `INTERACT_RADIUS` and presses Interact action (**E** keyboard, **A** gamepad)
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

---

## 11. Input

Canonical mapping lives in `input/input_actions.gd` and Project → Input Map; the player-facing controls table lives in `README.md`. Summary:

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | WASD | Left stick |
| Run | Shift | Y |
| Jump | Space | A |
| Look / orbit camera | Mouse | Right stick |
| Zoom | Wheel / V / B | L2 / R2 |
| Interact / advance dialogue | E | A (Switch-layout physical A) |
| Pause | Esc | Start |
| Toggle minimap | M | Select (−) |
| Debug HUD | H or ★ | — |
| Attack / dodge | (M9) | X / B (M9) |

`input/input_actions.gd` converts to an `Action` enum with `held`, `pressed`, `released` each frame. `input/gamepad.gd` owns deadzone, confirm/cancel layout (Switch vs Xbox), and trigger zoom. When adding an action, update all three places: Input Map, `input_actions.gd`, README table.

---

## 12. UI

- **Dialogue box**: bottom third, speaker name, portrait placeholder, line text
- **HUD**: minimal — interact prompt when in range ("Press E or A to talk")
- **Minimap**: top-right, 2D overhead of area collision grid + player dot (toggle M)
- **Pause menu**: resume, quit
- **Debug HUD** (M6): FPS, collision overlay toggle (H), entity picker (stretch)

All UI in `CanvasLayer`. UI logic scripts must not manipulate 3D scene directly.

---

## 13. Milestone roadmap

Build in order. Each milestone = playable build.

**Status note**: several M6 items were completed early during the TPC migration (playground, debug HUD, grounded actors). **M5 remains the next milestone** — do not start remaining M6 items until M5's checklist is complete and its exit criteria pass. This section is the single source of truth for milestone status; `README.md` and `AGENTS.md` must point here rather than duplicate it.

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

- [x] Lumi follows via AStarGrid2D
- [x] Stop distance, repath, stuck teleport fallback
- [x] Depth sort by Z (3D playground uses GPU depth; 2D Y-bias reserved for isometric areas)
- [x] **Autonomous idle (logic)** — wander near idle player; sit / play / groom state machine in `core/companion/`
- [x] **Meow barks** — random speech bubble via `Events.companion_barked` + `ui/companion_bark.tscn`
- [ ] Idle animation clips in `cat.glb` (`sit`, `play`, `groom`) — names wired in `config.gd`; art pending

### M4: NPC + dialogue

- [x] Elder Cat NPC in village area
- [x] Interact → dialogue box with 3 hardcoded lines
- [x] Advance / dismiss; gameplay input blocked during dialogue
- [x] Interact prompt when near NPC (early — full polish in M6)
- [x] Player faces NPC when dialogue opens (early — M6)

### M5: Area transitions

- [ ] Second area `forest_path.tscn`
- [ ] TransitionZone triggers fade + load + spawn at NamedSpawn
- [ ] Bidirectional travel; companion persists

### M6: Mechanics polish

- [x] TPC playground as default dev area
- [x] Unified debug HUD (H toggle, shortcuts, player state)
- [x] Grounded companions + NPCs (`GroundedCharacter`)
- [ ] Walk all paths without snagging (manual checklist)
- [ ] Camera clamp at area edges
- [x] Interact prompt UI (E / A)
- [x] Player faces NPC on talk
- [x] Minimap with player dot
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
| Player | Jeheno Godot plush (addon GLB) | Addon texture |
| Lumi (companion) | `cat.glb` under `Visual/Model` | Cream `#F5E6C8` |
| NPC cat | BoxMesh rounded 0.5×0.7 | Grey-lavender `#9B8FA8` |
| Ground | PlaneMesh or BoxMesh 1×0.1×1 tiles | Moss `#7CB87C` |
| Wall / blocker | BoxMesh | Stone `#8A8490` |
| Transition zone | transparent BoxMesh (visible in debug) | Cyan wireframe |
| Pressure plate | CylinderMesh r=0.4, emissive when active | Pink `#FF88CC` |
| Tree (decoration) | Sphere + cylinder stack | Green `#5A9E5A` |

Materials: `StandardMaterial3D` with `shading_mode = SHADING_MODE_UNSHADED` or mild toon; `roughness = 0.9`; no normal maps in placeholder phase.

---

## 15. Agent implementation notes

Coding standards, workflow, and definition of done live in **`AGENTS.md`** — read it first. Project-specific notes:

1. **Implement milestones in order** per §13. Official next: **M5** (area transitions). **M3 companion autonomy** may proceed in parallel — core logic in `core/companion/`, scene wiring in `scenes/companion/`.
2. **Match 2D prototype feel** for companion follow pacing and interact radius — reference `reference/whiskerbound-2d-prototype` when tuning. Player movement is governed by Jeheno TPC physics (§4), not grid wall-slide.
3. **No pixel art, no voxels, no free-orbit camera changes** beyond what the Jeheno TPC already provides.
4. **After each milestone**: update §13 checkboxes and the Status header, update `README.md` status line, run `bash scripts/run_smoke_test.sh`, commit as `M5: area transitions with fade`.
5. Target: Godot 4.7, macOS Apple Silicon, 60 FPS on placeholder assets.

### Verification (M1)

Headless smoke test (no display required):

```bash
bash scripts/run_smoke_test.sh
# Expected: SMOKE_OK: player at (...) companion at (...) area=playground
```

Interactive: open project in Godot 4.7 and press **F5**. WASD to move; **H** toggles debug HUD (collision overlay, player state including on-floor).

### Verification (M3)

Smoke test verifies A* pathfinding, companion follow simulation, and spawn beside player:

```bash
bash scripts/run_smoke_test.sh
# Expected: SMOKE_OK with player and companion positions
```

Walk away from Lumi in-game — she follows and stops ~1.25 units away. Stand still ~2 s — she wanders, sits, or grooms nearby; occasional meow bubble appears above her head.

### Verification (M4)

Elder Cat stands in the TPC playground near spawn. Walk nearby — "Press E or A to talk" appears. Press **E** or gamepad **A** to advance three lines; again to close. Movement is blocked while the dialogue box is open.

---

## 16. Authors & roles

- **Igor**: engineering, architecture, camera tuning, systems
- **Yvonne**: level layout in Godot Editor, narrative, NPC dialogue content, pacing