extends Node

## SceneFlow：用 Resource 流程图（FlowGraph）控制游戏进程。
## - flags-only：推进依据仅来自 GameState.flags（外部系统把 HotSpot/Dialogic/Timer 等事件转成 set_flag）。
## - 显式图：Step 完成后解锁 next_ids，支持多起点并行。

signal room_changed(room_id: String, room_node: Node)
signal step_activated(step_id: String)
signal step_completed(step_id: String)
signal flow_completed(graph_id: String)

@export var start_room_id: String = "room_01"
@export_file("*.tres") var active_flow_path: String = "res://flows/room_01_flow.tres"
@export var auto_start_flow: bool = true

var _room_registry: Dictionary = {
	"room_01": "res://scenes/rooms/Room_01.tscn",
}

var _current_room_id: String = ""
var _current_room: Node = null

enum StepStatus {
	LOCKED,
	ACTIVE,
	COMPLETED,
}

var _active_flow: Resource = null
var _status_by_id: Dictionary = {} # step_id -> StepStatus
var _unlocked_by_id: Dictionary = {} # step_id -> bool
var _flow_done: bool = false
var _pump_queued: bool = false
var _pumping: bool = false

@onready var _game_state: Node = get_node("/root/GameState")


func _ready() -> void:
	if _game_state.has_signal("flag_changed"):
		if not _game_state.flag_changed.is_connected(_on_flag_changed):
			_game_state.flag_changed.connect(_on_flag_changed)


func start_game() -> void:
	goto_room(start_room_id)
	if auto_start_flow:
		start_flow()


func start_flow() -> void:
	_flow_done = false
	_status_by_id.clear()
	_unlocked_by_id.clear()

	_active_flow = _load_flow()
	if _active_flow == null:
		push_error("SceneFlow: failed loading flow: %s" % active_flow_path)
		return
	if _active_flow.has_method("rebuild_index"):
		_active_flow.call("rebuild_index")

	# 初始化：全部 LOCKED + 未解锁
	for id in _active_flow.call("all_step_ids"):
		_status_by_id[id] = StepStatus.LOCKED
		_unlocked_by_id[id] = false

	# 多起点：并行解锁
	for id in _active_flow.get("start_step_ids"):
		_unlock_step(id)

	_request_pump()


func goto_room(room_id: String) -> void:
	if room_id == _current_room_id and _current_room != null:
		return

	var entry: Variant = _room_registry.get(room_id, null)
	if entry == null:
		push_error("SceneFlow: unknown room_id: %s" % room_id)
		return

	var packed: PackedScene = null
	if entry is PackedScene:
		packed = entry
	elif entry is String:
		packed = load(entry) as PackedScene

	if packed == null:
		push_error("SceneFlow: failed loading room scene for room_id: %s" % room_id)
		return

	var root := _get_room_root()

	# 卸载旧房间
	if _current_room != null and is_instance_valid(_current_room):
		_current_room.queue_free()
		_current_room = null
		_current_room_id = ""

	# 加载新房间
	var room_node := packed.instantiate()
	root.add_child(room_node)
	_current_room = room_node
	_current_room_id = room_id

	room_changed.emit(room_id, room_node)
	# 热点的可点击由各自 conditions + GameState.flags 控制；SceneFlow 不再硬编码。


func get_current_room() -> Node:
	return _current_room


func get_current_room_id() -> String:
	return _current_room_id


func _get_room_root() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		push_error("SceneFlow: current_scene is null")
		return self

	if scene.has_node("RoomRoot"):
		return scene.get_node("RoomRoot")

	# 兜底：如果主场景没有 RoomRoot，就创建一个（避免空指针）
	var room_root := Node2D.new()
	room_root.name = "RoomRoot"
	scene.add_child(room_root)
	return room_root

func _on_flag_changed(_flag_name: String, _value: bool) -> void:
	_request_pump()


func _request_pump() -> void:
	if _pump_queued:
		return
	_pump_queued = true
	call_deferred("_pump")


func _pump() -> void:
	_pump_queued = false
	if _pumping:
		return
	_pumping = true

	if _active_flow == null:
		_pumping = false
		return

	# 反复推进，直到没有新变化（解锁/激活/完成可能连锁）
	var changed := true
	while changed and not _flow_done:
		changed = false

		# 1) LOCKED 但已解锁且满足 enable 条件 => 激活
		for step_id in _status_by_id.keys():
			if int(_status_by_id[step_id]) != StepStatus.LOCKED:
				continue
			if not bool(_unlocked_by_id.get(step_id, false)):
				continue

			var step: Resource = _active_flow.call("get_step", str(step_id))
			if step == null:
				continue
			if bool(step.call("is_enabled", _game_state)):
				_activate_step(str(step.get("step_id")))
				changed = true

		# 2) ACTIVE 且满足 complete 条件 => 完成并解锁 next
		for step_id in _status_by_id.keys():
			if int(_status_by_id[step_id]) != StepStatus.ACTIVE:
				continue

			var step: Resource = _active_flow.call("get_step", str(step_id))
			if step == null:
				continue
			if bool(step.call("is_complete", _game_state)):
				_complete_step(step)
				changed = true

		# 3) 完成判定（优先：存在 End step 且已完成；否则：全部完成）
		if _is_flow_complete():
			_flow_done = true
			flow_completed.emit(str(_active_flow.get("graph_id")))
			break

	_pumping = false


func _unlock_step(step_id: String) -> void:
	if not _unlocked_by_id.has(step_id):
		return
	_unlocked_by_id[step_id] = true


func _activate_step(step_id: String) -> void:
	if not _status_by_id.has(step_id):
		return
	if int(_status_by_id[step_id]) != StepStatus.LOCKED:
		return

	_status_by_id[step_id] = StepStatus.ACTIVE
	step_activated.emit(step_id)

	var step: Resource = _active_flow.call("get_step", step_id)
	if step:
		for a in step.get("on_enter_actions"):
			if a and a.has_method("apply"):
				a.call("apply", _game_state)


func _complete_step(step: Resource) -> void:
	var step_id: String = str(step.get("step_id"))
	_status_by_id[step_id] = StepStatus.COMPLETED

	# 引擎内置：自动写一个 “<step_id>_completed” flag，便于后继步骤 enable_flags_all 引用
	_game_state.call("set_flag", "%s_completed" % step_id, true)

	step_completed.emit(step_id)

	for a in step.get("on_complete_actions"):
		if a and a.has_method("apply"):
			a.call("apply", _game_state)

	for next_id in step.get("next_ids"):
		if _unlocked_by_id.has(next_id):
			_unlocked_by_id[next_id] = true


func _is_flow_complete() -> bool:
	if _active_flow == null:
		return false

	# 约定：如果图里存在 End 节点，则 End 完成即算通关
	if _status_by_id.has("End") and int(_status_by_id["End"]) == StepStatus.COMPLETED:
		return true

	# 否则所有 step 都完成才算完成
	for step_id in _status_by_id.keys():
		if int(_status_by_id[step_id]) != StepStatus.COMPLETED:
			return false
	return true


func _load_flow() -> Resource:
	if active_flow_path.is_empty():
		return null
	return load(active_flow_path)
