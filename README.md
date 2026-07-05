# Whiskerbound

3D exploration and narrative adventure — Godot 4, soft stylised isometric camera, cat companion.

**Status:** M3 complete — Lumi follows via A*. **Next:** M4 (NPC + dialogue).

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

```
core/companion_logic.gd   — A* follow, repath, stuck teleport
core/pathfinding.gd       — AStarGrid2D from collision grid
scenes/companion/         — Lumi placeholder (cream sphere)
```

See `PROJECT.md` for full architecture.

## Archive

Design reference: [whiskerbound-2d-prototype](https://github.com/Ig0rFB/whiskerbound-2d-prototype)
