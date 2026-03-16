extends Node

## 最小桥接：把 HotSpot 点击事件转成 GameState flags（供 flags-only 的 SceneFlow 使用）。
##
## 用法：
## - 把这个脚本挂到主场景（或任意常驻节点）
## - 配置 `mapping`：hotspot_id -> flag_name
## - 或开启 `auto_flag`：按 hotspot_id 自动生成 flag（默认：hs_<id>_done）

@export var mapping: Dictionary = {} # String -> String

@export var auto_flag: bool = true
@export var auto_prefix: String = "hs_"
@export var auto_suffix: String = "_done"
@export var only_when_interactable_ok: bool = true

@onready var _event_bus: Node = get_node("/root/EventBus")
@onready var _game_state: Node = get_node("/root/GameState")

var _runtime_mapping: Dictionary = {}


func _ready() -> void:
	if not _event_bus.hotspot_action.is_connected(_on_hotspot_action):
		_event_bus.hotspot_action.connect(_on_hotspot_action)


func _on_hotspot_action(payload: Dictionary) -> void:
	if only_when_interactable_ok and not bool(payload.get("interactable_ok", false)):
		return

	var hotspot_id := str(payload.get("hotspot_id", ""))
	if hotspot_id.is_empty():
		return

	var flag_name := ""
	if _runtime_mapping.has(hotspot_id):
		flag_name = str(_runtime_mapping[hotspot_id])
	elif mapping.has(hotspot_id):
		flag_name = str(mapping[hotspot_id])
	elif auto_flag:
		flag_name = _auto_flag_name_for(hotspot_id)

	if flag_name.is_empty():
		return
	_game_state.call("set_flag", flag_name, true)


func set_runtime_mapping(new_mapping: Dictionary) -> void:
	_runtime_mapping = new_mapping.duplicate(true)


func clear_runtime_mapping() -> void:
	_runtime_mapping.clear()


func _auto_flag_name_for(hotspot_id: String) -> String:
	var token := hotspot_id.strip_edges().to_lower()
	if token.is_empty():
		return ""
	if not auto_prefix.is_empty() and token.begins_with(auto_prefix):
		return "%s%s" % [token, auto_suffix]
	return "%s%s%s" % [auto_prefix, token, auto_suffix]

