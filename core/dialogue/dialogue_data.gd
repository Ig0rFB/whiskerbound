class_name DialogueData
## Hardcoded dialogue lines for V1 (ported from 2D prototype dialogue.odin).

const ELDER_CAT_LINES: Array[String] = [
	"Ah, a traveller! Welcome to our little island.",
	"My old bones remember when every corner had a cat napping in the sun.",
	"Seek them out — they each have a story worth hearing.",
]


static func dialogue_id_for_npc(npc_id: String) -> int:
	match npc_id:
		"elder_cat":
			return 0
		_:
			return -1


static func speaker_name(dialogue_id: int) -> String:
	match dialogue_id:
		0:
			return "Elder Cat"
		_:
			return "???"


static func line_count(dialogue_id: int) -> int:
	return lines_for_id(dialogue_id).size()


static func get_line(dialogue_id: int, line_index: int) -> String:
	var lines := lines_for_id(dialogue_id)
	if line_index < 0 or line_index >= lines.size():
		return ""
	return lines[line_index]


static func lines_for_id(dialogue_id: int) -> Array[String]:
	match dialogue_id:
		0:
			return ELDER_CAT_LINES
		_:
			return []
