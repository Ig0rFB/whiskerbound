class_name DialogueData
## Hardcoded dialogue lines for V1 (ported from 2D prototype dialogue.odin).

const HELLO_LINE: Array[String] = ["Hello."]


static func dialogue_id_for_npc(npc_id: String) -> int:
	match npc_id:
		"bat":
			return 0
		"gdbot":
			return 1
		"gobot":
			return 2
		"sophia":
			return 3
		"beetle":
			return 4
		_:
			return -1


static func speaker_name(dialogue_id: int) -> String:
	match dialogue_id:
		0:
			return "Bat"
		1:
			return "GDBot"
		2:
			return "Gobot"
		3:
			return "Sophia"
		4:
			return "Beetle"
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
		0, 1, 2, 3, 4:
			return HELLO_LINE
		_:
			return []
