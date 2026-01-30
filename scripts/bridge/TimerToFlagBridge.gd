extends Node

## 最小桥接：延迟 N 秒后 set_flag。
##
## 用法：在任意地方调用
##   get_node("/root/TimerToFlagBridge").set_flag_after("some_flag", 1.0)
##
## 或把它挂在主场景任意节点上，通过 NodePath 找到调用。

@onready var _game_state: Node = get_node("/root/GameState")


func set_flag_after(flag_name: String, delay_sec: float) -> void:
	if flag_name.is_empty():
		return
	await get_tree().create_timer(delay_sec).timeout
	_game_state.call("set_flag", flag_name, true)

