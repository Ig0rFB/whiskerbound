# Companion Navigation Revamp - Plan

Replace the companion's grid-A* locomotion with Godot-native `NavigationAgent3D` +
`NavigationRegion3D`, keeping the 2D `CollisionGrid` for minimap/debug/tests (PROJECT.md section 4
dual-layer model). Follow-quality only; the companion "brain" (roam/meow/cat behaviour) is a
separate later phase.

## Why

`PROJECT.md` section 4 already flags that the coarse playground grid does not mirror the CSG walls,
so A* paths through cells the player cannot walk. A baked navmesh from the real geometry fixes that,
gives multi-level pathing over the elevated CSG tops, and is engine-idiomatic (AGENTS.md: prefer
boring native Godot).

## Constraints discovered

- Actors stand on **elevated CSG platforms around y=6**, not the y=0 ground. The ground collider is
  an infinite `WorldBoundaryShape3D` (not bakeable); the visual ground is a 110x110 `PlaneMesh` at
  y=0. The navmesh must come from the **CSG geometry** (and optionally the ground plane), not the
  WorldBoundary.
- `village_green` has no navmesh. The companion must **fall back to the existing grid follow** when
  no navmesh region exists on its navigation map (fail-safe; keeps the legacy area working).
- Smoke test calls `CompanionLogic` directly (pure logic). Keep that file; it doubles as the
  fallback motor. Do not delete it.

## Design

- **Navmesh setup lives in `scenes/areas/playground.gd`** (no `.tscn` edits): build a
  `NavigationRegion3D` under `WorldOffset` in code, configure a `NavigationMesh` from config
  tunables, tag `CSGCombiner3D` (+ ground mesh) into a source group, bake at runtime on load.
- **`companion.gd` motor**: if a navmesh region exists on the agent's map, drive movement from
  `NavigationAgent3D` (set target = follow goal, steer toward `get_next_path_position()`, arrive
  and stop within follow distance). Otherwise fall back to `CompanionLogic` grid follow.
- **Follow goal** keeps the existing feel: player position + velocity lead
  (`COMPANION_PREDICT_SECONDS`) + per-slot lateral offset.
- Multi-companion avoidance (RVO) left OFF for this pass (single companion); noted for later.

## Checklist (tick as landed; commit + push per item)

- [x] Plan document committed (this file)
- [x] 1. Config: navmesh bake + agent tunables in `config.gd`
- [x] 2. Playground: attach a `NavigationRegion3D` with a pre-baked navmesh (offline bake tool
      `scenes/tools/bake_playground_navmesh.gd`; runtime bake fallback kept)
- [x] 3. Companion: `NavigationAgent3D` child + nav motor with grid fallback, goal snapped to navmesh
- [x] 4. Debug path overlay reads the nav path (`get_debug_path()` returns the agent path)

## Verification

- `bash scripts/run_smoke_test.sh` prints `SMOKE_OK`, zero new warnings (pure-logic companion tests
  unchanged; they still exercise `CompanionLogic`).
- Headless nav harness (scratchpad): load playground, wait for bake, assert the navmesh has polygons
  on the actor level (~y=6), a path from companion to player is non-empty, and after simulating
  physics the companion ends within follow distance of the player.
- Manual (Igor): F5, walk the player around the playground including onto/around the CSG structures;
  Lumi should path around obstacles (not clip through) and keep pace, stopping near the player.

## Known limitations / follow-ups

- The follow goal is snapped onto the navmesh, so the companion will not chase a point off an
  edge. It can still, in principle, corner-cut near an unrailed platform edge (no physical wall on
  the CSG tops). Not observed in the on-platform follow test; revisit with level guard rails or a
  tighter `path_desired_distance` if it shows up in play.
- `scenes/companion/companion.gd` is now ~380 lines (over the ~300 guideline). Propose splitting the
  motor (nav + grid follow) out of the scene script before the brain phase extends it further.
- Multi-companion RVO avoidance is OFF; debug-spawned extra companions rely on the grid fallback's
  nudge only where the grid path runs. Enable `NavigationAgent3D` avoidance if multiple companions
  become a real scenario.

## Deferred (next phase, after Igor tests)

- Update `PROJECT.md` section 4 / section 9.2, `README.md`, `companion logic.md` to describe the nav model.
- Companion brain: roam/circle/stop, random meow + lines (bark lines already exist), idle cat
  behaviours. Blend follow with companion-owned urges per `companion logic.md`.
