# Whiskerbound

3D exploration and narrative adventure — Godot 4, soft stylised isometric camera, cat companion.

**Status:** M2 complete — 8-direction movement, grid collision, wall sliding. **Next:** M3 (companion follow).

## Requirements

- [Godot 4.3+](https://godotengine.org/download) (developed on 4.7)
- macOS Apple Silicon (primary target)

## Quick start

```bash
open -a Godot .
# Press F5 to play
```

## Verify

```bash
bash scripts/run_smoke_test.sh
```

Expected: `SMOKE_OK: player at (10.0, 0.0, 8.0) area=village_green`

## Controls

| Key | Action |
|-----|--------|
| WASD / Arrows | Move (8 directions) |
| H | Toggle collision debug overlay |
| E / Space | Interact (M4+) |
| M | Toggle minimap (M6+) |
| Esc | Pause |

## Stack

- Godot 4.7, Forward+
- GDScript
- Jolt Physics (3D)

## Project layout

See `PROJECT.md` for full architecture.

```
core/collision_grid.gd    — solid/walkable grid (XZ)
core/movement.gd          — wall-slide velocity (pure logic)
input/input_actions.gd    — InputMap polling
scenes/debug/             — collision overlay (H)
scenes/areas/village_green.*
```

## Archive

Design reference: [whiskerbound-2d-prototype](https://github.com/Ig0rFB/whiskerbound-2d-prototype)
