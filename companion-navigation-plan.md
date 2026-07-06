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

- [ ] Plan document committed (this file)
- [ ] 1. Config: navmesh bake + agent tunables in `config.gd`
- [ ] 2. Playground: build + bake `NavigationRegion3D` at runtime from CSG geometry
- [ ] 3. Companion: `NavigationAgent3D` child + nav motor with grid fallback
- [ ] 4. Debug path overlay reads the nav path (keep `get_debug_path()` meaningful)

## Verification

- `bash scripts/run_smoke_test.sh` prints `SMOKE_OK`, zero new warnings (pure-logic companion tests
  unchanged; they still exercise `CompanionLogic`).
- Headless nav harness (scratchpad): load playground, wait for bake, assert the navmesh has polygons
  on the actor level (~y=6), a path from companion to player is non-empty, and after simulating
  physics the companion ends within follow distance of the player.
- Manual (Igor): F5, walk the player around the playground including onto/around the CSG structures;
  Lumi should path around obstacles (not clip through) and keep pace, stopping near the player.

## Deferred (next phase, after Igor tests)

- Update `PROJECT.md` section 4 / section 9.2, `README.md`, `companion logic.md` to describe the nav model.
- Companion brain: roam/circle/stop, random meow + lines (bark lines already exist), idle cat
  behaviours. Blend follow with companion-owned urges per `companion logic.md`.
