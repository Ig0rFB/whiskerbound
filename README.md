# Whiskerbound

3D exploration and narrative adventure — Godot 4, soft stylised isometric camera, cat companion.

**Status:** M1 complete — village area, isometric camera, player spawn. **Next:** M2 (grid movement + collision).

## Requirements

- [Godot 4.3+](https://godotengine.org/download) (developed on 4.7)
- macOS Apple Silicon (primary target)

## Quick start

```bash
# Open in editor
open -a Godot .
# Or run from terminal
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Press **F5** (Play) to run `scenes/main.tscn`.

## Verify

```bash
bash scripts/run_smoke_test.sh
```

Expected output: `SMOKE_OK: player at (10.0, 0.0, 8.0) area=village_green`

Headless and interactive runs were checked on Godot 4.7 with no script errors or engine warnings.

## Stack

- Godot 4.7, Forward+
- GDScript
- Jolt Physics (3D)

## Project layout

See `PROJECT.md` for full architecture and milestone roadmap.

```
scenes/main.tscn              — entry point
scenes/areas/village_green.*  — first playable area
scenes/camera/camera_rig.*    — fixed isometric follow camera
scenes/player/player.*        — placeholder capsule
config.gd                     — tunables (camera, colours, speeds)
autoloads/                    — GameState, Events
core/                         — pure logic (no Node dependencies)
scripts/run_smoke_test.sh     — headless M1 regression check
```

## Controls (M2+)

| Key | Action |
|-----|--------|
| WASD / Arrows | Move |
| E / Space | Interact |
| M | Toggle minimap |
| Esc | Pause |

## Archive

Design reference only: [whiskerbound-2d-prototype](https://github.com/Ig0rFB/whiskerbound-2d-prototype) (Odin/Raylib pixel V1).
