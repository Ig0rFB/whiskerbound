# Whiskerbound

3D exploration and narrative adventure — Godot 4, soft stylised isometric camera, cat companion.

**Status:** M4 complete — Elder Cat dialogue. **Next:** M5 (area transitions).

## Quick start

```bash
open -a Godot .
# Press F5
```

## Verify

```bash
bash scripts/run_smoke_test.sh
```

## Controls

| Input | Action |
|-------|--------|
| WASD / Arrows | Move |
| Left stick / D-pad | Move (gamepad) |
| E / Space / **A** | Talk / advance dialogue |
| Esc / **Start** | Pause menu |
| M / **Select (−)** | Toggle minimap |
| H | Toggle debug HUD (colliders, stats) |
| R | Restart area *(debug HUD on)* |
| C | Spawn companion *(debug HUD on, max 8)* |
| L | Reload current area *(debug HUD on)* |

Connect an **8BitDo SN30 Pro** (or any pad) via Bluetooth/USB — movement uses the left stick with a dead zone; face buttons match Xbox layout (A = confirm, Start = pause).

## Try M4

Walk south-east to the grey **Elder Cat** NPC. Press **E** to talk through three lines.

## Stack

Godot 4.7 · GDScript · Forward+

See `PROJECT.md` for architecture. Prototype reference: [whiskerbound-2d-prototype](https://github.com/Ig0rFB/whiskerbound-2d-prototype)
