extends Node
## Typed signal bus — decouple systems (PROJECT.md §6.3).

signal player_interacted(source_id: int, target_id: int)
signal dialogue_started(npc_id: int)
signal dialogue_ended
signal item_collected(item_id: String)
signal puzzle_solved(puzzle_id: String)
signal area_entered(area_id: String)
signal cat_found(cat_id: String)
signal combat_hit(attacker_id: int, target_id: int)
signal collision_debug_toggled(show_it: bool)
signal debug_restart_requested
signal debug_reload_area_requested
signal debug_spawn_companion_requested
signal companion_barked(companion: Node3D, text: String)
signal interact_target_changed(target_name: String)
signal interactable_triggered(owner: Node)
