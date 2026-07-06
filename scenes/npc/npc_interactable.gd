extends Interactable
## Bridges reference-style raycast hits to Whiskerbound dialogue.


func interact(_user: Node) -> void:
	var owner: Node = get_parent()
	if owner == null:
		return
	Events.interactable_triggered.emit(owner)
