extends Node

## RoomController：方案1的“执行器”
## - 监听 EventBus.hotspot_action
## - 只处理属于当前房间（父节点子树内）的热点
## - 负责执行：对话、背包、flags、切房间、动画等

@export var enable_debug_log: bool = false

@onready var _event_bus: Node = get_node("/root/EventBus")
@onready var _game_state: Node = get_node("/root/GameState")
@onready var _inventory: Node = get_node("/root/Inventory")
@onready var _scene_flow: Node = get_node("/root/SceneFlow")


func _ready() -> void:
	if not _event_bus.hotspot_action.is_connected(_on_hotspot_action):
		_event_bus.hotspot_action.connect(_on_hotspot_action)


func _on_hotspot_action(payload: Dictionary) -> void:
	# 仅处理“当前房间树”内的热点
	var node_path: NodePath = payload.get("node_path", NodePath())
	if node_path == NodePath():
		return
	var node := get_tree().root.get_node_or_null(node_path)
	if node == null:
		return
	if not _is_descendant_of_room(node):
		return

	if enable_debug_log:
		print("RoomController: ", payload.get("hotspot_id"), " state=", payload.get("state_id"))

	var interactable_ok := bool(payload.get("interactable_ok", false))

	# 1) 如果配置了对话 timeline，优先播放（常用于 locked 提示等）
	var dialog_timeline := str(payload.get("dialog_timeline", ""))
	if not dialog_timeline.is_empty():
		_play_dialog(dialog_timeline)

	# 2) 动作只在可交互时执行（避免锁定状态也触发 set_flag/pickup）
	if not interactable_ok:
		return

	# 3) 执行动作（按顺序）
	var actions: Array = payload.get("actions", [])
	for a in actions:
		if a is Dictionary:
			await _execute_action(a, payload)


func _is_descendant_of_room(n: Node) -> bool:
	var room_root := get_parent()
	if room_root == null:
		return false
	var cur: Node = n
	while cur != null:
		if cur == room_root:
			return true
		cur = cur.get_parent()
	return false


func _play_dialog(timeline_path: String) -> void:
	var dialogic := get_tree().root.get_node_or_null("/root/Dialogic")
	if dialogic == null:
		push_warning("RoomController: /root/Dialogic not found")
		return
	dialogic.start(timeline_path)


func _execute_action(action: Dictionary, payload: Dictionary) -> void:
	var t := str(action.get("type", ""))
	var p: Dictionary = action.get("params", {})

	match t:
		"pickup":
			var item_key := str(p.get("item_key", ""))
			if item_key.is_empty():
				return

			# 可选：飞入动画（从热点位置飞到背包栏）
			var fly := bool(p.get("fly", true))
			if fly:
				var ui := get_tree().current_scene.get_node_or_null("UI_inventory")
				if ui != null and ui.has_method("play_item_gain_fly"):
					var from_pos := Vector2.ZERO
					var n := get_tree().root.get_node_or_null(payload.get("node_path", NodePath()))
					if n is Node2D:
						from_pos = (n as Node2D).global_position
					await ui.call("play_item_gain_fly", item_key, from_pos)

			_inventory.call("add_item", item_key)

		"consume_item":
			var item_key := str(p.get("item_key", ""))
			if item_key.is_empty():
				return
			_inventory.call("remove_item", item_key)

		"set_flag":
			var flag_name := str(p.get("name", ""))
			var value := bool(p.get("value", true))
			if flag_name.is_empty():
				return
			_game_state.call("set_flag", flag_name, value)

		"clear_flag":
			var flag_name := str(p.get("name", ""))
			if flag_name.is_empty():
				return
			_game_state.call("set_flag", flag_name, false)

		"change_room":
			var room_id := str(p.get("room_id", ""))
			if room_id.is_empty():
				return
			_scene_flow.call("goto_room", room_id)

		"play_animation":
			var player_path := NodePath(str(p.get("player_path", "")))
			var anim_name := str(p.get("anim", ""))
			if player_path == NodePath() or anim_name.is_empty():
				return
			var player := get_parent().get_node_or_null(player_path)
			if player == null:
				return
			if player.has_method("play"):
				player.call("play", anim_name)

		_:
			# examine/open_puzzle 等留给后续扩展
			pass
