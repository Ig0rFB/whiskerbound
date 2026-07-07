class_name CompanionBarkLines
## Random meow / bark strings for companion speech bubbles.


const LINES: Array[String] = [
	"Mew?",
	"Mrrrow.",
	"Prrt!",
	"*yawn*",
	"...",
	"Mew mew!",
	"*stretches*",
	"*licks paw*",
	"*grooms*",
	"Purrrr...",
	"*flicks tail*",
	"Mrp!",
]


static func random_line() -> String:
	if LINES.is_empty():
		return "Mew?"
	return LINES[randi() % LINES.size()]
