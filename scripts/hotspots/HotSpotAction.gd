class_name HotSpotAction
extends Resource

enum ActionType {
	EXAMINE,
	PICKUP,
	CONSUME_ITEM,
	OPEN_PUZZLE,
	CHANGE_ROOM,
	PLAY_ANIMATION,
	SET_FLAG,
	CLEAR_FLAG,
}

@export var type: ActionType = ActionType.EXAMINE
@export var params: Dictionary = {}


func type_to_string() -> String:
	match type:
		ActionType.EXAMINE:
			return "examine"
		ActionType.PICKUP:
			return "pickup"
		ActionType.CONSUME_ITEM:
			return "consume_item"
		ActionType.OPEN_PUZZLE:
			return "open_puzzle"
		ActionType.CHANGE_ROOM:
			return "change_room"
		ActionType.PLAY_ANIMATION:
			return "play_animation"
		ActionType.SET_FLAG:
			return "set_flag"
		ActionType.CLEAR_FLAG:
			return "clear_flag"
		_:
			return "examine"


func to_dict() -> Dictionary:
	return {
		"type": type_to_string(),
		"params": params.duplicate(true),
	}
