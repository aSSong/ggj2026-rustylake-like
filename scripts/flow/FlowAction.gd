class_name FlowAction
extends Resource

enum ActionType {
	SET_FLAG,
}

@export var type: ActionType = ActionType.SET_FLAG

@export var flag_name: String = ""
@export var flag_value: bool = true


func apply(game_state: Node) -> void:
	if game_state == null:
		return

	match type:
		ActionType.SET_FLAG:
			if flag_name.is_empty():
				return
			game_state.call("set_flag", flag_name, flag_value)

