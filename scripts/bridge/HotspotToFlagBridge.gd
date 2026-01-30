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
	if mapping.has(hotspot_id):
		flag_name = str(mapping[hotspot_id])
	elif auto_flag:
		flag_name = "%s%s%s" % [auto_prefix, hotspot_id.to_lower(), auto_suffix]

	if flag_name.is_empty():
		return
	_game_state.call("set_flag", flag_name, true)

