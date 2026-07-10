# WHISKERBOUND — Project Brief & Architecture (3D / Godot)

> **Status**: **M5 next** (area transitions — see §13). M3 brain/meow **shipped**; remaining M3 = idle anim clips + optional blend (polish only). M6 items landed early: GDQuest playground, unified debug HUD, grounded companion.
> **Engine**: Godot 4.7 (Forward+) · **Language**: GDScript  
> **Authors**: Igor Barbosa (engineering), Yvonne Reinhardt (narrative & level design)  
> **Full historical copy**: `docs/archive/PROJECT-full-2026-07.md` (do not treat as live TODO)

Coding standards and workflow: **`AGENTS.md`**. Companion brain: **`docs/companion-brain.md`**. Asset paths: **`assets/ASSETS.md`**. Tunables: **`config.gd`** (do not copy constant values into this doc).

---

## 1. Vision (short)

Exploration-and-narrative 3D adventure: walk, talk, explore, light puzzles, collect cats, minimal combat. Warm stylised 3D — **not** voxel, pixel art, or combat-heavy. 2D Odin/Raylib prototype is design/algorithm reference only (`reference/whiskerbound-2d-prototype`).

**As-built vs prototype:** player collision is 3D physics (not grid wall-slide). Companion pathing is **navmesh-first** with grid A* fallback (§4).

---

## 2. Art direction

Placeholder primitives until real art (§14). No pixel art, no voxels. Biome colour palette not locked — use placeholders until Yvonne sets one.

---

## 3. Camera specification

**Gameplay:** GDQuest third-person orbit (`scenes/player/gdquest/Camera/orbit_view.tscn`). Zoom: mouse wheel / `=` / `−`.

**Do not revive:** fixed OOTS `scenes/camera/camera_rig.tscn` is editor preview only.

**Coordinates:** Y up; movement on XZ; logical south = +Z. 1 tile = 1 m. Map 2D `(x, y)` → `(x, height, z)` with `z = tile_y`.

**Viewport:** UI base `GameSettings.UI_BASE_RESOLUTION` (1920×1080); stretch `canvas_items`; default window `Config.VIEWPORT_*`; target 60 fps.

---

## 4. Grid, movement & collision

Dual-layer model: **3D physics** for actors vs geometry; **2D logic grid** for minimap, debug, tests, and companion pathing **only as navmesh fallback**.

### Layer 1 — 3D physics (primary)

**Trap — playground bits ≠ config names.** `config.gd` uses `COLLISION_LAYER_WORLD := 1` and `COLLISION_LAYER_CHARACTER := 2` for `GroundedCharacter` / village. The **playground** follows the GDQuest reference bit assignment:

| Bit | `config.gd` name | Playground (reference) | Village / `GroundedCharacter` default |
|---|---|---|---|
| 1 | `COLLISION_LAYER_WORLD` | **NPC bodies** | World geometry |
| 2 | `COLLISION_LAYER_CHARACTER` | **World CSG / ground** | Player, companion, NPCs |

When adding to **playground**, use the playground column. Elsewhere with `GroundedCharacter` defaults, use the config constants.

**Player** — `scenes/player/player.tscn` + `whiskerbound_player.gd` over GDQuest `scenes/player/gdquest/`. `CharacterBody3D` + capsule; orbit camera; interaction ray `collision_mask = 3`. Adapt only via `WhiskerboundPlayer`; do not edit `gdquest/` in place. Source: `reference/untitled-game/Player/`.

**Companion** — extends `GroundedCharacter`. Playground: layer **2**, mask **3**. Locomotion: **`NavigationAgent3D`** on baked `NavigationRegion3D` (`playground_navmesh.tres` via `playground.gd`); grid `CompanionLogic` fallback where no navmesh (e.g. `village_green`). Formation point behind player; speeds/distances in `config.gd` (`COMPANION_*`, `NAV_*`). Rebake navmesh with `scenes/tools/bake_playground_navmesh.gd` when walkable CSG changes.

**Playground NPCs** — `scenes/npc/npc.tscn` + `reference_npc.gd` (reference `NPCBody`): layer **1**, mask **2**; scene Y; floating Bat builds a floor-to-flyer `StaticBody3D` column (vertical gap was the walk-under bug — not FLOATING mode). Tunables: `NPC_FLOATING_*` in `config.gd`.

**Playground geometry:** CSG/ground layer **2**, mask **2**.

### Layer 2 — Logic grid

`core/world/collision_grid.gd` on XZ (`GRID_CELL` in `config.gd`). Playground grid is coarse and **does not** mirror CSG walls. `village_green` keeps a full painted grid for regression. Feet sampling (`core/movement/`) is for grid logic / village — **not** player wall collision.

---

## 5. Technology stack

Godot 4.7 · GDScript · macOS Apple Silicon primary · level authoring in Godot Editor · placeholder primitives then Blender. CI: add when needed.

---

## 6. Architecture principles

### 6.1 Strict layer separation

```
input/   → hardware → abstract actions
core/    → pure logic; NO autoloads; NO scene lookups outside own children; NO res:// scenes
scenes/  → nodes, meshes, animation; calls core
ui/      → Control nodes
```

Pure-logic scripts must not extend `Node`. **Sole Node-base exception:** `core/world/grounded_character.gd`. Adding another requires a note here.

### 6.2 Data-oriented state

As-built: `autoloads/game_state.gd` (mode, area id, Node refs, quest flags — **not** an ECS/`EntityStore`).

### 6.3 Event-driven decoupling

Signals: `autoloads/events.gd`. Reserved signals (combat, cat collection, puzzles) — emit only when that feature lands.

### 6.4 Configuration as data

All tunables live in **`config.gd`**. Point at named constants; never duplicate values in docs.

---

## 7. Project structure (as-built)

```
config.gd · PROJECT.md · README.md · AGENTS.md · docs/
autoloads/   game_state, game_settings, events
core/        companion/, dialogue/, interaction/, movement/, pathfinding/, world/, …
input/       input_actions, gamepad
scenes/      main, areas/{playground,village_green}, companion, npc, player/, tools/
ui/          game_ui, debug_hud, minimap, dialogue, interact_prompt, companion_bark, pause
scripts/     run_smoke_test.sh, run_companion_visual_test.sh, run_companion_behaviour_test.sh
assets/      see ASSETS.md
addons/      GDQuest character packs, camera_preview
reference/   untitled-game (player/NPC source), whiskerbound-2d-prototype
```

Not created yet (add when the milestone needs them): `data/`, `scenes/areas/forest_path.tscn`, CI workflow.

---

## 8. Game loop

Updates live in scene scripts, gated by `GameState.mode`. Companion: brain (optional) → nav motor (or grid fallback) → physics. Cross-scene via `Events` only. Do not migrate to a central dispatcher unless per-scene updates become unmanageable.

---

## 9. Core systems

### 9.0 GroundedCharacter

`core/world/grounded_character.gd` — capsule, gravity, floor snap. Defaults: layer/mask from `Config.COLLISION_LAYER_*`; body size from `CHARACTER_BODY_*` / override with `COMPANION_*` or `NPC_*` **before** `super._ready()`.

**Checklist — new grounded actor**

1. Root **CharacterBody3D** (not `Node3D`).
2. `extends "res://core/world/grounded_character.gd"`.
3. Set `body_radius` / `body_height` before `super._ready()`.
4. `Visual` child; feet at root origin; collision on root.
5. `_physics_process`: horizontal velocity → `apply_gravity` → `move_and_slide`.
6. Programmatic spawn: set XZ, `call_deferred("snap_to_floor")`.
7. Playground NPCs: use `npc.tscn` + `reference_npc.gd` (layer **1**, mask **2**) — not this base.

**Do not:** set `global_position.y` from raycasts each frame; put collision only on a visual child.

### 9.1 Player

See §4. Hooks: `feet_velocity`, `GameState` / `Events`, interact prompt via ray (§9.3).

### 9.2 Cat companion (Lumi)

Nav follow + `CompanionBrain` when settled/leashed. **Do not gate on player FSM** (that coupling failed once). Live open items: `docs/companion-brain.md`. Files: `scenes/companion/companion.gd`, `CompanionVisual`, `core/companion/*`.

### 9.3 NPC interaction

Aim with camera ray (mask **3**) → `Interactable` → `Events` → `game_ui` dialogue. Prompt: `ui/interact_prompt.tscn`. Source pattern: `reference/untitled-game/`.

### 9.4 Dialogue

Hardcoded / `DialogueData` by `dialogue_id` for V1.

### 9.5 Area transitions (M5)

`TransitionZone` Area3D → fade → load area → spawn at `NamedSpawn`; companions persist. Second area: `forest_path.tscn` (not created yet).

### 9.6–9.8 Later (after M6)

M7 puzzles · M8 cat collection · M9 minimal combat. Do not implement early.

---

## 10. Area authoring (Yvonne)

Each area `.tscn`: ground/geometry, optional `CollisionGrid`, markers (`PlayerSpawn`, `NamedSpawn`, `TransitionZone`, `NPCSpawn`, …). Designer places markers in the Godot Editor. Keep that workflow.

---

## 11. Input

Controls table: **`README.md`**. When adding input: Input Map + `input/input_actions.gd` + README.

---

## 12. UI

Dialogue, interact prompt, minimap, pause, debug HUD (**H**) — under `ui/`. All in `CanvasLayer`. UI scripts must not manipulate the 3D scene directly.

---

## 13. Milestone roadmap

**Official next: M5.** Do not start remaining M6 items until M5 exit criteria pass. Leftover M3 polish only as small scoped fixes (`docs/companion-brain.md`) — no companion scope expansion without approval.

### Shipped (summary)

- ✅ **M1–M2** — window, areas, camera evolution, collision grid / debug (player wall collision later replaced by 3D physics — §4)
- ✅ **M3** — navmesh follow, formation, `CompanionBrain` roam/meow, `CompanionVisual` (open: idle clips in `cat.glb`, optional blend/RVO)
- ✅ **M4** — NPC dialogue, aim prompt, face-on-talk
- ✅ **M6 early** — playground default, debug HUD, grounded companion / reference NPCs

### Open

**M3 polish**

- [ ] Idle animation clips in `cat.glb` (`sit`, `play`, `groom`) — names in `config.gd`; art pending
- [ ] Optional: blended follow+roam weighting; `NavigationAgent3D` RVO

**M5 — Area transitions**

- [ ] Second area `forest_path.tscn`
- [ ] TransitionZone triggers fade + load + spawn at NamedSpawn
- [ ] Bidirectional travel; companion persists

**M6 — remaining**

- [ ] Walk all paths without snagging (manual)
- [ ] Camera clamp at area edges
- [ ] Fade timing tuned

**M6 exit criteria:** spawn → explore village → transition to forest → return; talk to Elder Cat; companion follows; no collision snags.

---

## 14. Placeholder asset spec

| Entity | Placeholder |
|---|---|
| Player | GDQuest Godot plush (`scenes/player/gdquest/`) |
| Lumi | `cat.glb` under `Visual/Model` |
| NPC (village) | BoxMesh until skin |
| Ground / walls | Plane/Box primitives; playground uses reference CSG |

See `assets/ASSETS.md` for paths. Simple `StandardMaterial3D` in placeholder phase.

---

## 15. Agent implementation notes

1. Read **`AGENTS.md`** first; prefer this file’s §4, §6.1, §9, §13 for architecture.
2. Official next: **M5**. Exception: leftover M3 polish only as in §13 / `docs/companion-brain.md`.
3. After each milestone: update §13 + status header + README status line; run smoke tests; commit `M5: …`.
4. `docs/archive/` is historical — never a TODO list.

---

## 16. Authors & roles

- **Igor**: engineering, architecture, systems
- **Yvonne**: level layout in Godot Editor, narrative, NPC dialogue, pacing
