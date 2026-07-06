class_name Interactable
extends Node
## Base for raycast-targeted interactables (reference untitled-game pattern).


## Called when the player presses interact while aiming at this object.
func interact(_user: Node) -> void:
	print("Interacted with ", get_parent().name)
