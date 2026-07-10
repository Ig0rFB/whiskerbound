# Companion logic — design plan (Whiskerbound / Lumi)

> **ARCHIVED — RESEARCH.** Phase 1 (brain + meow on nav motor) is **shipped**.
> Do not implement from this file. Live status: `docs/companion-brain.md`. As-built: `PROJECT.md` §9.2 / §13.

**Status:** Historical research (March–July 2026)  
**Author:** Igor + agent (research-backed)  
**Goal:** Give companions their own continuous “thinking” loop — roaming, idling, and vocalising — **while always respecting follow** as the highest-priority locomotion need. This replaces the failed approach of branching follow vs autonomous based on **player idle/walk state**.

> **Update (July 2026):** the **Motor** layer is now realised as a `NavigationAgent3D` follow on a baked `NavigationRegion3D` (see `PROJECT.md` §4 / §9.2 and `docs/archive/companion-navigation-plan.md`). The brain phases below build on that nav motor; where this doc says `CompanionLogic` "follow motor", read it as the **grid fallback**. The follow goal is already a fanned point behind the player, so the brain adds **roam/activity/vocalise** on top of the nav follow rather than replacing it.

---

## 1. Why the current approach failed

We tried:

- Detecting player idle via `feet_velocity`, `InputActions`, Jeheno `State: Idle`, and config toggles.
- Switching `companion.gd` between `CompanionLogic` (follow) and `CompanionIdleLogic` (wander/sit/meow).

**Problems observed:**

1. **Coupling** — companion behaviour depended on player state machine timing, which Jeheno owns; any mismatch froze movement or trapped Lumi in autonomous sit/groom.
2. **Exclusive branches** — follow and roam were mutually exclusive `if/else` paths; one bug in the gate broke all locomotion.
3. **Wrong mental model** — industry companions are not “idle when player idle”; they run **parallel desires** (stay near leader *and* fidget, sniff, sit) blended every tick.

**Decision:** Remove player-state gating from `companion.gd`. Follow-only shipping behaviour stays as today. New work lives behind a **companion-centric brain** (see §5).

---

## 2. Research — how other games do it

### 2.1 Utility / priority stacks (BioWare, Sims, Dragon Age)

**Dragon Age: Inquisition — Behavior Decision System (BDS)**  
[Game AI Pro 3, Ch. 31 — Behavior Decision System (PDF)](https://www.gameaipro.com/GameAIPro3/GameAIPro3_Chapter31_Behavior_Decision_System_Dragon_Age_Inquisition%E2%80%99s_Utility_Scoring_Architecture.pdf)

- Combat and scripted actions are **behaviour snippets** scored each decision cycle.
- **Follow the leader** is a snippet with a **low constant score** (e.g. 0) — it runs whenever nothing more important wins.
- Variants (combat follow, “hold position”) score higher only in context.
- **Tether / return-home** snippets score high only when the NPC leaves an allowed area.

**Takeaway for Whiskerbound:** Follow is not a mode switch; it is the **default low-priority behaviour** that always runs unless a higher-scored companion desire wins *briefly*.

**The Sims — bucketing**  
[AI and Games — How Utility AI Helps NPCs Decide (YouTube)](https://www.youtube.com/watch?v=p3Jbp2cZg3Q)

- Motives are grouped into priority buckets; only the top bucket is considered.
- Prevents “dance” from beating “go to toilet.”

**Takeaway:** Use **hard priority tiers**: `CatchUp` > `Follow` > `Roam` > `PerformActivity` > `Vocalise`.

**Utility AI overview**  
[recited.io — Utility-Based AI Systems](https://recited.io/kb/ai-in-game-development/npc-behavior-and-intelligence/utility-based-ai-systems/)

- **Soft constraints** multiply weights (e.g. story mission: stay near player ×2.5).
- **Hard constraints** set floors/ceilings (emergency heal overrides stay-near).

**Takeaway:** Later, quests can bias roam radius without disabling the brain.

---

### 2.2 Steering & leader following (Reynolds, GDC)

**Steering behaviours — leader following**  
[Craig Reynolds — Steering Behaviors For Autonomous Characters (GDC 1999)](https://www.red3d.com/cwr/steer/gdc99/)

- Leader follow = **arrival** toward a point **slightly behind** the leader + **separation** from other followers + **evade** if blocking the leader’s path.
- Combines multiple forces with weights; no single FSM state.

**Tuts+ summary**  
[Understanding Steering Behaviors: Leader Following](https://code.tutsplus.com/understanding-steering-behaviors-leader-following--gamedev-10810t)

**Takeaway:** Whiskerbound already has slot offsets and follow distance in `CompanionLogic`; roaming should add a **secondary wander offset** blended only when catch-up urgency is low.

**Flocking / leader-follower**  
[Socratopia — Game AI Patterns, Ch. 17 Flocking](https://www.socratopia.app/library/game-ai-patterns-en/chapter-17)

- Production squads bias cohesion/alignment toward a **designated leader** (player).

---

### 2.3 Ambient life & routines (Skyrim, Dragon Age Origins)

**Skyrim ambient AI (reverse-engineering notes)**  
[Černý — An AI System for Large Open Virtual Worlds (AIIDE 2014)](http://popelka.ms.mff.cuni.cz/~cerny/papers/WarhorseAI_AIIDE_2014.pdf)  
(See also companion notes: [AIOpenWorlds.pdf](http://popelka.ms.mff.cuni.cz/~cerny/AIOpenWorlds.pdf))

- NPCs choose **places + animation sequences** per time window; movement between spots is part of the routine.
- Player proximity activates simulation; distant NPCs simplify.

**Dragon Age Toolset — ambient behaviour**  
[Ambient behaviour wiki](http://www.datoolset.net/wiki/Ambient_behaviour)

- **Bubble around player** (~50 m): alternates **movement phase** (waypoint) and **animation phase**.
- Designer-tunable via `AMBIENT_*` vars; persisted across save.

**Takeaway:** Lumi’s roam radius should be **player-centred** (not map-global), with phases: `move_to_poi` → `play_anim` → `meow`.

---

### 2.4 Companion-specific craft (Fable 2, TLOU2, modern plugins)

**Fable 2 dog (GDC 2007)**  
[IGN — Fable 2: In the Dog House](https://www.ign.com/articles/2007/03/08/gdc-2007-fable-2-in-the-dog-house)

- Dog **scouts ahead**, reacts to expressions, fetches, alerts to danger — **always autonomous**, not gated on player idle.
- Emotional bond drives tricks; locomotion AI is continuous.

**The Last of Us 2 — companion positioning (student research summary)**  
[HvA GPE — State-Based Companion Unity](https://summit-2223-sem2.game-lab.nl/2023/04/11/state-based-companion-unity/)

- Companions try to stay **ahead** or **visible**; speed rigged so player cannot awkwardly pass them.
- **Sit ↔ wander** loop: at rest, random nearby wander then sit again — **companion-local state machine**, not player idle detection.

**Game Creator 2 Companion System (reference architecture)**  
[CPS documentation](https://www.c-huck.com/pages/projects/unitydoc/cps)

- Separate modules: `FollowBehavior`, `IdleBehavior` (POI visits when owner stationary), `BondingBehavior`.
- **Proximity tiers + hysteresis** for follow; idle runs on its own timer when owner is still.

**Takeaway:** Split **Motor** (how to move) from **Brain** (what goal to pursue). Idle when owner stationary is optional seasoning; **roam while following** is the Whiskerbound priority.

---

### 2.5 Behaviour trees as glue

**Behaviour trees — priority by structure**  
[Generalist Programmer — Behavior Trees Tutorial](https://generalistprogrammer.com/tutorials/game-ai-behavior-trees-complete-implementation-tutorial)

- Root **selector**: first succeeding child wins (combat → investigate → patrol).
- **Patrol** is default leaf when nothing else applies — same pattern as BDS “follow score 0.”

**Utility selectors in BTs**  
[Game AI Pro — Building Utility Decisions into Behavior Trees (PDF)](https://www.gameaipro.com/GameAIPro/GameAIPro_Chapter10_Building_Utility_Decisions_into_Your_Existing_Behavior_Tree.pdf)

- Replace static selector order with **utility-scored children**.

**Takeaway for Godot:** We do not need a BT addon on day one; a **small priority-ordered list of desires** in `core/` is enough (matches `AGENTS.md` pure-logic layer).

---

## 3. Design principles for Whiskerbound

| Principle | Meaning |
|-----------|---------|
| **Companion-owned brain** | Desires computed from companion distance, energy, timers, POIs — not player FSM. |
| **Follow never off** | Roam modifies *goal offset* or *short detours*; catch-up always wins when distance > leash. |
| **Blend, don’t branch** | One locomotion pipeline per frame: `desired_feet = follow_goal.lerp(roam_goal, roam_weight)` then existing grid path + physics. |
| **core/ pure logic** | Brain in `core/companion/`; `companion.gd` applies results (signals up, calls down). |
| **Designer data later** | Tunables in `config.gd` now; future `CompanionPersonality` Resource for Yvonne. |
| **Fail safe** | If brain disabled or errors, behaviour degrades to today’s `CompanionLogic.update` only. |

---

## 4. Proposed architecture

```
┌─────────────────────────────────────────────────────────┐
│  scenes/companion/companion.gd  (Motor)                  │
│  - read brain output                                    │
│  - NavigationAgent3D follow (grid CompanionLogic fallback)│
│  - AnimationPlayer + Events.companion_barked            │
└───────────────────────────┬─────────────────────────────┘
                            │ CompanionBrainStep (data)
┌───────────────────────────▼─────────────────────────────┐
│  core/companion/companion_brain.gd  (NEW)               │
│  - evaluate desires each tick (or every N physics frames)│
│  - output: locomotion_goal, activity, bark_text         │
└───────────────────────────┬─────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
 companion_follow_*   companion_roam_*    companion_vocal_*
 (reuse CompanionLogic) (refactor idle)   (meow cooldown)
```

### 4.1 Desire tiers (priority order)

1. **CatchUp** — distance > `COMPANION_LEASH_SOFT` (e.g. 4 m): goal = player feet only; roam weight = 0.
2. **Follow** — default: `CompanionLogic` goal (predicted player + slot offset).
3. **Roam** — distance < soft leash *and* roam timer elapsed: add wander POI near player (`COMPANION_WANDER_RADIUS`).
4. **Activity** — when roam reaches POI: sit / groom / play anim (reuse `CompanionActivity` enum).
5. **Vocalise** — independent meow timer (`CompanionBarkLines`); does not block locomotion.

### 4.2 Roam while following (key mechanic)

Instead of “player idle → wander”:

- Each companion maintains `roam_urge` (0–1), rising slowly over time (~30–60 s).
- When `roam_urge > threshold` **and** within soft leash, brain picks a POI within wander radius (clear grid cell near player).
- **Locomotion goal** = `follow_goal` blended toward `poi` with weight `roam_urge * (1 - catchup_urgency)`.
- Completing POI or player distance increasing resets `roam_urge`.

This matches Reynolds (**secondary steering**) + DA ambient (**local POI**) + Fable (**always-on scout/roam**).

### 4.3 Config toggles (future)

| Constant | Purpose |
|----------|---------|
| `COMPANION_BRAIN_ENABLED` | Master switch; `false` = current follow-only. |
| `COMPANION_LEASH_SOFT` | Start reducing roam blend. |
| `COMPANION_LEASH_HARD` | CatchUp only (existing stuck teleport). |
| `COMPANION_ROAM_URGE_RATE` | How fast boredom builds. |
| Existing `COMPANION_WANDER_RADIUS`, `COMPANION_MEOW_*`, anim names | Reused |

**Do not** reintroduce `COMPANION_AUTONOMOUS_IDLE_ENABLED` tied to player state.

---

## 5. Implementation phases

### Phase 0 — Done (March 2026)

- [x] Follow-only `companion.gd` restored (A* + horizontal velocity).
- [x] Player-state autonomous branch **removed** from scene.
- [x] Core idle files kept for refactor (`companion_idle_logic.gd`, etc.) but **not wired**.

### Phase 1 + roam/meow — Shipped (July 2026)

Landed on the `NavigationAgent3D` motor (not grid `CompanionLogic`):

- [x] `core/companion/companion_brain.gd` — `evaluate(...) -> CompanionBrainStep` (pure logic).
- [x] `core/companion/companion_brain_step.gd` — `target_feet`, `hold`, `following`, `activity`, `bark_text`.
- [x] `config.gd` — `COMPANION_BRAIN_ENABLED` (default **true** so it is visible), `COMPANION_LEASH_SOFT`, `COMPANION_CIRCLE_*`; reuses `COMPANION_WANDER_RADIUS`, `COMPANION_ACTIVITY_*`, `COMPANION_MEOW_*`.
- [x] `scenes/companion/companion.gd` — brain picks the nav goal when the player is settled near; **follow (formation point) wins** whenever the player moves or the cat strays past the leash.
- [x] Activities: **wander** (random points), **circle** (orbit), **sit / groom** (hold). Meow on its own timer via `Events.companion_barked` → existing bark UI. Behaviour-flavoured lines added to `CompanionBarkLines`.
- [x] Verified headlessly: idle player → roam + meow; moving player → follow wins; multi-companion spread holds.

**Not yet (future):** true blended follow+roam weighting (current is a hard tier override, which reads fine for a cat); `CompanionActivity` animation hooks (no clips in `cat.glb` yet); POI markers; personality Resource; debug HUD activity line. The old grid `CompanionIdleLogic`/`CompanionIdleStep` remain unused and can be retired or folded once the nav roam is proven in play.

### Phase 2 — Roam + activities

**Files**

- Refactor `companion_idle_logic.gd` → `companion_roam_logic.gd` (POI pick, path slice; no player idle checks)
- `companion_data.gd` — `roam_urge`, `roam_target`, remove `idle_timer` player coupling

**Behaviour**

- Wander along short A* legs; at POI play sit/groom/play (placeholder anim pause until clips exist)
- Meow via existing `Events` + `ui/companion_bark.tscn`

### Phase 3 — Polish

- POI markers in area scenes (`CompanionPoi` Marker3D for sniff spots — designer workflow per `PROJECT.md` §9)
- Personality Resource (roam frequency, vocalise rate)
- Debug HUD line: `Lumi: follow 0.8 / roam 0.2 → POI sniff`

---

## 6. What we keep vs retire

| Asset | Action |
|-------|--------|
| `companion_logic.gd` | **Keep** — grid follow fallback + stuck recovery (nav motor is primary) |
| `companion_idle_logic.gd` | **Refactor** → roam/POI helper; delete player-idle gates |
| `companion_activity.gd`, `companion_bark_lines.gd` | **Keep** |
| `TpcPlayer.is_locomotion_idle()` | **Optional** future consideration input only — not a branch gate |
| `COMPANION_AUTONOMOUS_IDLE_ENABLED` | **Removed** |
| `ui/companion_bark.*` | **Keep** — wire in Phase 2 |

---

## 7. Success criteria

1. With `COMPANION_BRAIN_ENABLED = false`, behaviour **identical** to today (smoke test green).
2. With brain enabled, player walking across playground: Lumi **always** keeps pace (no frozen path-draw).
3. With brain enabled, player stationary 60 s: Lumi makes **short detours** and returns without teleporting.
4. Meow bubbles appear ≤ once per `COMPANION_MEOW_MIN_INTERVAL` on average; never spam per frame.
5. No `get_parent()` / player FSM checks in `core/` — only distance, velocity optional, grid, timers.

---

## 8. References (quick links)

| Topic | Source |
|-------|--------|
| DA:I utility + follow-as-default | [Game AI Pro 3 Ch.31 PDF](https://www.gameaipro.com/GameAIPro3/GameAIPro3_Chapter31_Behavior_Decision_System_Dragon_Age_Inquisition%E2%80%99s_Utility_Scoring_Architecture.pdf) |
| Utility AI / narrative constraints | [recited.io utility AI](https://recited.io/kb/ai-in-game-development/npc-behavior-and-intelligence/utility-based-ai-systems/) |
| Sims bucketing | [AI and Games YouTube](https://www.youtube.com/watch?v=p3Jbp2cZg3Q) |
| Steering / leader follow | [Reynolds GDC 1999](https://www.red3d.com/cwr/steer/gdc99/) |
| Leader following tutorial | [Tuts+](https://code.tutsplus.com/understanding-steering-behaviors-leader-following--gamedev-10810t) |
| Skyrim / open-world ambient | [Černý AIIDE 2014](http://popelka.ms.mff.cuni.cz/~cerny/papers/WarhorseAI_AIIDE_2014.pdf) |
| Dragon Age ambient phases | [DAO Toolset wiki](http://www.datoolset.net/wiki/Ambient_behaviour) |
| Fable 2 dog AI | [IGN GDC 2007](https://www.ign.com/articles/2007/03/08/gdc-2007-fable-2-in-the-dog-house) |
| TLOU2 sit/wander pattern | [HvA companion research](https://summit-2223-sem2.game-lab.nl/2023/04/11/state-based-companion-unity/) |
| Follow + idle modules | [Game Creator CPS](https://www.c-huck.com/pages/projects/unitydoc/cps) |
| Behaviour trees + utility | [Game AI Pro Ch.10 PDF](https://www.gameaipro.com/GameAIPro/GameAIPro_Chapter10_Building_Utility_Decisions_into_Your_Existing_Behavior_Tree.pdf) |
| BT priority overview | [Generalist Programmer BT tutorial](https://generalistprogrammer.com/tutorials/game-ai-behavior-trees-complete-implementation-tutorial) |

---

## 9. Next action for Igor

~~Superseded.~~ Phase 1 shipped with `COMPANION_BRAIN_ENABLED` default **true**. See `docs/companion-brain.md` for remaining open items. Do **not** merge follow/roam with player idle detection again.
