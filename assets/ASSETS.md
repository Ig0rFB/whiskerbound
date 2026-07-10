# Whiskerbound — Character & Level Assets

Imported from `reference/untitled-game/` (GDQuest character packs and shared art). Use these paths in scenes; run `godot --headless --import` after adding new models.

## Player

| Asset | Path | Notes |
|-------|------|-------|
| GDQuest player scene | `scenes/player/gdquest/PlayerCharacterScene.tscn` | State machine, orbit camera, interaction ray |
| Whiskerbound adapter | `scenes/player/whiskerbound_player.gd` | `class_name WhiskerboundPlayer` — GameState hooks only |
| Runtime entry | `scenes/player/player.tscn` | Instances gdquest scene + adapter script |
| Godot Plush model | `assets/art/godot_plush/` (from reference) | Default plush mesh in player scene |
| Adventurer (man) | `assets/models/characters/player/Adventurer-man.glb` | Future selectable protagonist |
| Adventurer (woman) | `assets/models/characters/player/Adventurer-woman.glb` | Future selectable protagonist |

Gameplay uses the **GDQuest reference controller** (`reference/untitled-game/`), not the unused Jeheno TPC addon.

## Companion

| Asset | Path | Notes |
|-------|------|-------|
| Cat (GLB) | `assets/models/characters/companion/cat.glb` | Lumi mesh |
| Cat (FBX) | `assets/models/characters/companion/cat.fbx` | Alternate import |
| Cat textures | `assets/models/characters/companion/cat_*.png` | Albedo / skin maps |
| Companion scene | `scenes/companion/companion.tscn` | Grounded follow AI |

## GDQuest character packs (`addons/`)

Each pack has a `*_skin.tscn` scene (model + animations) and a `*_skin.gd` script. Instance as a child of `scenes/npc/npc.tscn` to replace the placeholder box visual.

| Character | Skin scene | Model | Spawned in playground |
|-----------|------------|-------|----------------------|
| GDBot | `addons/gdquest_gdbot/gdbot_skin.tscn` | `gdbot.glb` | Yes |
| Gobot | `addons/gdquest_gobot/gobot_skin.tscn` | `gobot.glb` | Yes |
| Sophia | `addons/gdquest_sophia/sophia_skin.tscn` | `sophia.glb` | Yes |
| Beetle Bot | `addons/gdquest_beetle_bot/beetlebot_skin.tscn` | `beetle_bot_fused.glb` | Yes (0.66 scale) |
| Round Bat | `addons/gdquest_round_bat/round_bat_skin.tscn` | `bat.glb` | Yes (floating NPC) |
| Bee Bot | `addons/gdquest_bee_bot/bee_bot_skin.tscn` | `bee_bot.glb` | No — asset only |

Shared shaders and eye mask: `addons/gdquest_models_shared/`.

## Level / prototype materials

| Asset | Path | Notes |
|-------|------|-------|
| Grid material | `assets/materials/reference/grid_mat.tres` | From reference test map |
| Colour mats | `assets/materials/reference/*_mat.tres` | Red, blue, green, yellow |
| Prototype grid texture | `addons/JehenoThirdPersonController/Arts/godot-prototype-texture/` | Used by `playground.tscn` ground |

## Playground layout

`scenes/areas/playground.tscn` matches `reference/untitled-game/Scenes/TestMapScene.tscn` geometry and NPC positions (with `WorldOffset` 56, 0, 56 for the logic grid). Whiskerbound systems: HUD, pause, minimap, 8BitDo mapping, Lumi companion, dialogue via `game_ui.gd`.

**Collision (reference bits):** world CSG on layer **2**; NPC bodies on layer **1**. See `PROJECT.md` §4.

## Imported from reference

| Source | Destination | Purpose |
|--------|-------------|---------|
| `reference/untitled-game/Player/` | `scenes/player/gdquest/` | Player movement, camera, interaction ray |
| `reference/untitled-game/NPCs/` | `scenes/npc/reference/` | `NPCBody.gd`, `BaseNPC.tscn` template |
| `reference/untitled-game/Systems/Interactions/Interactable.gd` | `core/interaction/interactable.gd` | Raycast interactable base class |
| `reference/untitled-game/UI/InteractionPrompt.tscn` | `ui/reference_interaction_prompt.tscn` | Optional; gameplay uses `ui/interact_prompt.tscn` |

## Not used at runtime

- `addons/JehenoThirdPersonController/` — superseded by GDQuest player (kept in repo for prototype textures only)
- `scenes/player/tpc_player.gd` — legacy Jeheno adapter
- `reference/untitled-game/addons/gdquest_model_viewer_3d/` — editor-only model viewer plugin
