class_name Interactable
extends Node

# This will be the base for all interactable objects.
# It will have a function like "interact(user)" that
# can be overridden by specific objects (chests, NPCs, etc).

func interact(_user: Node):
	print("Interacted with ", get_parent().name)
