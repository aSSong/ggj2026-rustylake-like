extends Node

## flags-only 流程桥接：当 trigger_flag 变为 true 时，延迟 delay_sec 后 set done_flag=true。
##
## mapping:
## {
##   "delay_after_hs02_start": {"delay": 1.0, "done_flag": "delay_after_hs02_done"}
## }

@export var mapping: Dictionary = {}

@onready var _game_state: Node = get_node("/root/GameState")

var _in_flight: Dictionary = {} # trigger_flag -> bool


func _ready() -> void:
	if _game_state.has_signal("flag_changed"):
		if not _game_state.flag_changed.is_connected(_on_flag_changed):
			_game_state.flag_changed.connect(_on_flag_changed)


func _on_flag_changed(flag_name: String, value: bool) -> void:
	if not value:
		return
	if not mapping.has(flag_name):
		return
	if bool(_in_flight.get(flag_name, false)):
		return

	var cfg: Variant = mapping[flag_name]
	var delay_sec := float(cfg.get("delay", 0.0))
	var done_flag := str(cfg.get("done_flag", ""))
	if done_flag.is_empty():
		return

	_in_flight[flag_name] = true
	_run_delay(flag_name, delay_sec, done_flag)


func _run_delay(trigger_flag: String, delay_sec: float, done_flag: String) -> void:
	await get_tree().create_timer(delay_sec).timeout
	_game_state.call("set_flag", done_flag, true)
	_in_flight[trigger_flag] = false
