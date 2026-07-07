# Whiskerbound

3D exploration and narrative adventure — Godot 4, GDQuest third-person playground, cat companion follow.

**Status:** M5 next (area transitions) — see `PROJECT.md` §13. M3 companion autonomy in progress (idle wander, meows). M6 polish landed early: playground, debug HUD, grounded companion.

## Quick start

```bash
open -a Godot .
# Press F5
```

## Verify

```bash
bash scripts/run_smoke_test.sh
bash scripts/run_companion_visual_test.sh
bash scripts/run_companion_behaviour_test.sh
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

### Third-person player (GDQuest reference controller)

| Input | Action |
|-------|--------|
| WASD / left stick | Move |
| Shift / **Y** | Run |
| Space / A | Jump |
| Mouse / right stick | Look |
| Mouse wheel / **=** / **−** | Zoom in / out |
| Arrow keys | Pan camera |
| RMB / R-shoulder | Aim camera |
| T | Swap aim shoulder |
| Ctrl / L3 | Free / capture mouse |
| F10 | Ragdoll *(debug)* |

Connect an **8BitDo SN30 Pro** or **Switch Pro** via Bluetooth/USB. On Switch-layout pads, physical **A** confirms (talk); **Y** runs.

## Try it

Boot into the **playground**. Walk to an NPC and **aim your crosshair at them** — the prompt “Press E or A to talk” appears at the bottom of the screen. Press **E** or gamepad **A** to open dialogue. Press **H** for the debug HUD (player state, position, ray hit).

## Stack

Godot 4.7 · GDScript · Forward+ · GDQuest `untitled-game` player (`scenes/player/gdquest/`, adapted via `whiskerbound_player.gd`) · companion follow via `NavigationAgent3D` on a baked navmesh

See `PROJECT.md` for architecture — **§4** (dual-layer 3D physics + logic grid), **§9.1** (player), **§9.3** (NPC interaction), **§13** (milestones). `AGENTS.md` holds coding standards and workflow. Prototype reference: [whiskerbound-2d-prototype](https://github.com/Ig0rFB/whiskerbound-2d-prototype) (companion AI only — player collision is 3D physics). Player/interaction source of truth: `reference/untitled-game/`.
