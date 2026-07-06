class_name CompanionIdleStep
## One autonomous idle tick — pure data returned from CompanionIdleLogic.


var feet: Vector2 = Vector2.ZERO
var activity: CompanionActivity.Type = CompanionActivity.Type.NONE
var moving: bool = false
var bark_text: String = ""
