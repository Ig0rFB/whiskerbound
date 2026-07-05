# Whiskerbound — Agent Instructions

Read `PROJECT.md` before writing code. Implement milestones **in order** (M2 done; **M3 next**).

## Rules

- Godot 4, GDScript
- Keep `core/` free of Node dependencies — no autoload references in `class_name` scripts
- Placeholder primitives until real art — no pixel art, no voxels
- Target: macOS Apple Silicon, 1920×1080 viewport, 60 FPS
- British spelling in comments and user-facing strings

## After each milestone

1. Update milestone checklists and status in `PROJECT.md`
2. Update `README.md` (status, controls, verify steps)
3. Update this file only if workflow or rules change
4. Run `bash scripts/run_smoke_test.sh` — extend tests for new behaviour
5. Run the project headless and interactively; fix errors and warnings
6. Commit and push with message format: `M3: companion A* follow`

## Current milestone: M3

Lumi follows via `AStarGrid2D`, stop distance, repath, stuck teleport, depth sort by Z. See `PROJECT.md` §13.

## Reference

2D prototype (algorithms only): https://github.com/Ig0rFB/whiskerbound-2d-prototype
