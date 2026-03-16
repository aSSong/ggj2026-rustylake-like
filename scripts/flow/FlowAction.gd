class_name FlowAction
extends Resource

enum ActionType {
	SET_FLAG,
	CHANGE_ROOM,
}

@export var type: ActionType = ActionType.SET_FLAG

@export var flag_name: String = ""
@export var flag_value: bool = true
@export var room_id: String = ""


func apply(game_state: Node, context: Dictionary = {}) -> void:
	match type:
		ActionType.SET_FLAG:
			if game_state == null:
				return
			if flag_name.is_empty():
				return
			game_state.call("set_flag", flag_name, flag_value)

		ActionType.CHANGE_ROOM:
			if room_id.is_empty():
				return
			var scene_flow: Node = context.get("scene_flow", null)
			if scene_flow == null:
				return
			scene_flow.call("goto_room", room_id)

