# Whiskerbound

3D exploration and narrative adventure — Godot 4, third-person controller playground, cat companion follow.

**Status:** M5 next (area transitions) — see `PROJECT.md` §13 for the authoritative checklist. M6 items landed early: TPC playground, unified debug HUD, grounded companions/NPCs.

## Quick start

```bash
open -a Godot .
# Press F5
```

## Verify

```bash
bash scripts/run_smoke_test.sh
bash scripts/run_companion_visual_test.sh
```

## Controls

### Whiskerbound (dialogue, UI, debug)

| Input | Action |
|-------|--------|
| E / **A** (gamepad) | Talk / advance dialogue |
| Esc / **Start** | Pause menu |
| M / **Select (−)** | Toggle minimap |
| ★ (star) / H | Toggle debug HUD |
| R / C / L | Restart / +companion / reload area *(debug HUD on)* |

### Third-person player (Jeheno TPC)

| Input | Action |
|-------|--------|
| WASD / left stick | Move |
| Shift / **Y** | Run |
| Space / A | Jump |
| Mouse / right stick | Look |
| Mouse wheel / V / B | Zoom in / out |
| **L2 / R2** | Zoom out / in |
| RMB / R-shoulder | Aim camera |
| G | Swap aim shoulder |
| T | Toggle camera collision |
| Ctrl / L3 | Free / capture mouse |

Connect an **8BitDo SN30 Pro** or **Switch Pro** via Bluetooth/USB. On Switch-layout pads, physical **A** confirms (talk); **Y** runs.

## Try it

Boot into the **TPC playground** (Jeheno test map). Press **H** for the unified debug HUD (shortcuts, player state, position). Walk to the **Elder Cat** NPC — press **E** or **A** to talk.

## Stack

Godot 4.7 · GDScript · Forward+ · [Jeheno Third-Person Controller](addons/JehenoThirdPersonController/)

See `PROJECT.md` for architecture — **§4** (dual-layer 3D physics + logic grid), **§9.0** (`GroundedCharacter`), **§9.1** (player physics via Jeheno TPC), **§13** (milestones). `AGENTS.md` holds coding standards and workflow. Prototype reference: [whiskerbound-2d-prototype](https://github.com/Ig0rFB/whiskerbound-2d-prototype) (companion AI only — player collision is 3D physics).