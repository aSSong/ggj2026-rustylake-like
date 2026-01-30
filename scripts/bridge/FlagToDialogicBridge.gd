extends Node

## flags-only 流程桥接：当某个 start_flag 变为 true 时播放指定 Dialogic timeline，
## timeline 结束后 set done_flag=true。
##
## 由于 Dialogic.timeline_ended 信号不带参数，本桥接通过记录“最近一次由本桥接启动的 timeline”
## 来决定要置哪个 done_flag。

@export var mapping: Dictionary = {}
# 结构：
# {
#   "op_01_start": {"timeline":"res://dialogues/op_01.dtl", "done_flag":"op_01_done"},
#   "ed_01_start": {"timeline":"res://dialogues/ed_01.dtl", "done_flag":"ed_01_done"},
# }

@onready var _game_state: Node = get_node("/root/GameState")

var _dialogic: Node = null
var _pending_done_flag: String = ""
var _playing: bool = false


func _ready() -> void:
	_dialogic = get_node_or_null("/root/Dialogic")
	if _dialogic == null:
		push_warning("FlagToDialogicBridge: /root/Dialogic not found")
		return

	if _dialogic.has_signal("timeline_ended"):
		if not _dialogic.timeline_ended.is_connected(_on_timeline_ended):
			_dialogic.timeline_ended.connect(_on_timeline_ended)

	if _game_state.has_signal("flag_changed"):
		if not _game_state.flag_changed.is_connected(_on_flag_changed):
			_game_state.flag_changed.connect(_on_flag_changed)


func _on_flag_changed(flag_name: String, value: bool) -> void:
	if not value:
		return
	if _playing:
		return
	if not mapping.has(flag_name):
		return

	var cfg: Variant = mapping[flag_name]
	var timeline := str(cfg.get("timeline", ""))
	var done_flag := str(cfg.get("done_flag", ""))
	if timeline.is_empty() or done_flag.is_empty():
		return

	_pending_done_flag = done_flag
	_playing = true
	_dialogic.start(timeline)


func _on_timeline_ended() -> void:
	if not _playing:
		return
	_playing = false

	if not _pending_done_flag.is_empty():
		_game_state.call("set_flag", _pending_done_flag, true)
		_pending_done_flag = ""
