# Whiskerbound — Agent Instructions

Read `PROJECT.md` before writing code. Implement milestones **in order** (M4 done; **M5 next**).

## Rules

- Godot 4, GDScript
- Keep `core/` free of Node dependencies — no autoload references in `class_name` scripts
- Group pure logic by domain (`movement/`, `companion/`, `world/`, etc.)
- Placeholder primitives until real art
- British spelling in comments and user-facing strings

## After each milestone

1. Update `PROJECT.md`, `README.md`, and this file if needed
2. Run `bash scripts/run_smoke_test.sh`
3. Fix headless/interactive errors and warnings
4. Commit and push: `M5: area transitions with fade`

## Current milestone: M5

Second area `forest_path.tscn`, TransitionZone fade/load/spawn, bidirectional travel, companion persists.

## Reference

2D prototype: https://github.com/Ig0rFB/whiskerbound-2d-prototype
