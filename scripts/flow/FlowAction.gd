class_name FlowAction
extends Resource

enum ActionType {
	SET_FLAG,
	CHANGE_ROOM,
}

## 底层 FlowAction 类型。
## 通常不建议作者直接编辑；SimpleFlow 会自动生成这些动作。
@export_enum("Set Flag | 设置一个世界状态", "Change Room | 切换到另一个房间") var type: int = ActionType.SET_FLAG

## Set Flag 类型使用的 flag 名称。
@export var flag_name: String = ""
## Set Flag 类型写入的布尔值。
@export var flag_value: bool = true
## Change Room 类型使用的 room_id。
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

