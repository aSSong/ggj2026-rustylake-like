extends Node

## 最小桥接：把 Dialogic timeline 结束转成 GameState flags（供 flags-only 的 SceneFlow 使用）。
##
## mapping:
## - key: timeline 路径（例如 "res://dialogues/op_01.dtl"）
## - value: 结束后要 set 的 flag（例如 "intro_done"）

@export var mapping: Dictionary = {} # String -> String

@onready var _game_state: Node = get_node("/root/GameState")


func _ready() -> void:
	var dialogic := get_node_or_null("/root/Dialogic")
	if dialogic == null:
		push_warning("DialogicToFlagBridge: /root/Dialogic not found")
		return

	if dialogic.has_signal("timeline_ended"):
		if not dialogic.timeline_ended.is_connected(_on_timeline_ended):
			dialogic.timeline_ended.connect(_on_timeline_ended)


func _on_timeline_ended() -> void:
	# Dialogic 的 timeline_ended 信号不带参数；这里无法直接知道是哪条 timeline。
	# 因此这个桥接更推荐通过“你自己在合适时机 set_flag”或用 Dialogic 的 signal event 传参来实现。
	#
	# 这里做一个最小兜底：如果 mapping 只有一个条目，就把它置 true。
	if mapping.size() == 1:
		var flag_name := str(mapping.values()[0])
		if not flag_name.is_empty():
			_game_state.call("set_flag", flag_name, true)
