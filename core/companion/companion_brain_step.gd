class_name CompanionBrainStep
## One companion brain tick — pure data the motor applies (PROJECT.md §9.2, docs/companion-brain.md).


## Feet-space point the companion should navigate toward this tick.
var target_feet: Vector2 = Vector2.ZERO
## True when the companion should stop and stay put (sit / groom / reached a wander spot).
var hold: bool = false
## True in follow / catch-up mode; false while roaming near an idle player.
var following: bool = true
## Current autonomous activity (for future animation hooks and debug).
var activity: CompanionActivity.Type = CompanionActivity.Type.NONE
## Non-empty when the companion should emit a speech bubble this tick.
var bark_text: String = ""
