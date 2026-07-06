# Floating NPC Collision - Review & Fix Plan

Status of the floating-NPC (Bat) collision implementation in `scenes/npc/reference_npc.gd`,
plus the fixes agreed with Igor. Pick up from the checklist in section 4.

## 1. What the code does today

For a floating NPC (`motion_type = FLOATING`, e.g. the Bat in `scenes/areas/playground.tscn`),
`reference_npc.gd`:

1. Disables the body's own capsule (`_collision_shape.disabled = true`) in `_ready()`.
2. Waits exactly **2 physics frames** (`_floating_column_frames_remaining`).
3. Raycasts straight down to find the floor, estimates the skin's vertical extent from every
   child `VisualInstance3D` AABB, then builds a `StaticBody3D` + `BoxShape3D` column spanning
   from the floor up to `Config.NPC_FLOATING_COLUMN_TOP_LOCAL` (1.5 m above the body origin).

The column is placed on the NPC's `collision_layer` (playground bit 1 = "NPC bodies"). The player
body (`collision_mask = 3`) and the interaction ray (`collision_mask = 3`) both test bit 1, so the
column both **blocks the player** and **answers the interaction ray**. That behaviour is correct
and works in play.

## 2. Root cause of the original bug (corrected)

The earlier write-up claimed: *"Floating CharacterBody3D does not block the player - Godot only
treats grounded character bodies as solid obstacles for move_and_slide()."* **That is wrong** and
worth correcting so the myth does not propagate.

- `motion_mode` (GROUNDED vs FLOATING) only changes how *that* body computes *its own* movement
  (whether it has an up-direction / floor / wall / ceiling concept). It has **no** effect on
  whether other bodies collide with it.
- A `CharacterBody3D` is a solid obstacle to another body's `move_and_slide()` whenever their
  shapes overlap and the layer/mask bits line up, regardless of motion mode.

The real reason the player walked "through" the Bat was **vertical separation**: the Bat floats at
Y ~= 7.15 with a ~2 m capsule up in the air, while the player capsule is at ground level. The
shapes never overlapped; the player walked *under* the Bat. Enlarging the capsule radius never
helped because radius is horizontal.

The floor-to-flyer column is the right fix, but because it closes the vertical gap, **not** because
it is static rather than floating. A legitimate reason to use a `StaticBody3D` *child* (rather than
resizing the moving body's own shape) is to keep a floor-length shape off the moving body's physics
so it does not fight the ground if the Bat ever bobs/animates.

## 3. Findings

### To fix (code-only, low risk)

- **A. Misleading comment.** `reference_npc.gd` comment states floating bodies do not block the
  player. Replace with the accurate reason (vertical separation; static child avoids fighting the
  moving body's physics).
- **B. Fragile 2-frame deferral.** `_floating_column_frames_remaining = 2` is an unexplained magic
  wait for physics/skin readiness. If a skin or the physics space is not ready on frame 2, the
  column is built off bad data silently. Replace with an explicit readiness gate: build once the
  floor raycast actually hits, retrying each physics frame up to a bounded cap.
- **D. Silent floor-ray miss.** `_raycast_ground_local_y()` returns `0.0` on a miss, which is
  indistinguishable from a real floor at local Y 0 and silently mis-places the column. Make the
  miss observable (bounded retry via B, then a `push_warning` + documented fallback if the floor is
  never found).

### Needs Igor's decision (NOT to be implemented without approval)

- **E. Authored column vs runtime synthesis.** Building the shape at runtime (floor raycast + AABB
  walk over every `VisualInstance3D` + frame deferral) is a lot of machinery and couples collision
  to skin internals. Boring-Godot alternative that fits Yvonne's marker workflow: author an
  `InteractionColumn` (StaticBody3D + BoxShape3D) directly in `scenes/npc/npc.tscn` with an
  `@export var column_height`, sized in the editor. Trades "auto-fits any skin" for "designer sets
  one number." Touches `npc.tscn` (scene ownership rule) - decision required.
- **F. Altitude-dependent interaction.** `NPC_FLOATING_COLUMN_TOP_LOCAL = 1.5` is relative to the
  body origin, so "aim at roughly chest height to interact" only holds while the flyer sits near
  chest height. A Bat at Y=15 blocks fine but cannot be aimed at from normal height. If flyers will
  live at varied altitudes, the aim guarantee needs an altitude-independent source. Design decision.
- **G. `_find_skin_root()` brittleness.** Returns the first `Node3D` child that is not a
  CollisionShape3D / Interactable / column - order- and name-dependent. If runtime measurement is
  kept, an `@export var skin: Node3D` or a group tag is sturdier. Couples to scene edits - decide
  alongside E.

### Considered and intentionally NOT changed

- **Ground-ray mask precision.** `_raycast_ground_local_y()` masks `WORLD | CHARACTER` (bits 1|2).
  Narrowing it to "just the ground" is ambiguous because the playground maps ground to bit 2 while
  village/legacy maps world geometry to bit 1 (see PROJECT.md section 4). There is no single
  "ground" bit across areas, so keeping both bits is the safer choice. Left as-is by design.

## 4. Checklist (tick as landed; commit + push per item)

- [ ] Plan document committed (this file)
- [ ] A. Correct the misleading root-cause comment in `reference_npc.gd`
- [ ] B + D. Readiness-gated column build (retry until floor hit, cap, warn on miss);
      replaces the magic 2-frame deferral. Adds `NPC_FLOATING_COLUMN_MAX_ATTEMPTS` to `config.gd`.
- [ ] E. Decision on authored vs runtime column (blocked on Igor)
- [ ] F. Decision on altitude-independent interaction (blocked on Igor)
- [ ] G. Decision on `_find_skin_root` robustness (blocked on Igor; bundle with E)

## 5. Verification

- `bash scripts/run_smoke_test.sh` must print `SMOKE_OK` with zero new warnings. (The
  `RID allocations ... were leaked at exit` line is a known headless dummy-renderer artifact,
  unrelated to this work.)
- Manual (headless smoke test does not tick physics, so the column build path is not exercised
  there): run the playground (open in Godot, F5), walk into the Bat from the south of its spawn,
  confirm you are stopped by an invisible column from the ground up to the flyer, then press E
  while looking at roughly Bat height to get the interact prompt. Confirm the Godot output panel
  shows zero warnings on boot (item H sanity check for the shapeless floating body).
