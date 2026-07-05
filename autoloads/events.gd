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
