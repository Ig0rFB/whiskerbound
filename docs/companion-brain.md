# Companion brain (Lumi) — live status

**Status (July 2026):** Phase 1 **shipped**. Motor = `NavigationAgent3D` on a baked navmesh (grid `CompanionLogic` fallback). Brain = `CompanionBrain` in `core/companion/`, enabled by default (`COMPANION_BRAIN_ENABLED`).

Design research and rejected approaches: `docs/archive/companion-brain-research.md` (historical — do not implement from it).

## As-built

| Layer | Role | Files |
|---|---|---|
| **Motor** | Path to formation point behind player; grid fallback | `scenes/companion/companion.gd`, `CompanionLogic` |
| **Brain** | When player is settled and cat is leashed: wander / circle / sit / groom; meow on timer | `CompanionBrain`, `CompanionBrainStep` |
| **Priority** | Follow / catch-up always wins when the player moves or the cat strays past `COMPANION_LEASH_SOFT` | Hard tier override (not blended weights yet) |

Do **not** gate companion behaviour on the player FSM / idle state — that coupling failed once (see archive §1).

## Open (do not freestyle)

- [ ] Idle animation clips in `cat.glb` (`sit`, `play`, `groom`) — names already in `config.gd`
- [ ] Optional: blended follow+roam weighting; `NavigationAgent3D` RVO for multi-companion
- [ ] Later: POI markers, personality Resource, debug HUD activity line

**Milestone rule:** official next work is **M5** (area transitions). Remaining M3 items above are polish only — do not expand brain scope without Igor’s approval. See `PROJECT.md` §13 / §15.
