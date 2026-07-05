# Whiskerbound — Agent Instructions

Read `PROJECT.md` before writing code. Implement milestones **in order** (M1 done; **M2 next**).

## Rules

- Godot 4, GDScript
- Keep `core/` free of Node dependencies (no `extends Node`, no draw calls)
- Placeholder primitives until real art — no pixel art, no voxels
- Target: macOS Apple Silicon, 1920×1080 viewport, 60 FPS
- British spelling in comments and user-facing strings

## After each milestone

1. Update milestone checklists and status in `PROJECT.md`
2. Update `README.md` (status, verify steps, layout if changed)
3. Update this file only if workflow or rules change
4. Run `bash scripts/run_smoke_test.sh` (extend test when new behaviour lands)
5. Run the project (F5 or headless) and fix any errors or warnings
6. Commit and push with message format: `M2: grid movement + collision`

## Current milestone: M2

Grid movement on XZ, collision grid, wall sliding, feet-only sampling, collision debug overlay (H toggle). See `PROJECT.md` §13.

## Reference

2D prototype (algorithms only): https://github.com/Ig0rFB/whiskerbound-2d-prototype
