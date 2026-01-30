class_name HotSpotArea
extends Node2D

@export var hotspot_id: String = ""

## 视觉表现：在房间里直接拖拽替换热点图片
@export var visual_texture: Texture2D
@export var visual_visible: bool = true
@export var visual_modulate: Color = Color(1, 1, 1, 1)

const _ConditionsScript := preload("res://scripts/hotspots/HotSpotConditions.gd")
const _FeedbackScript := preload("res://scripts/hotspots/HotSpotFeedback.gd")
const _StateScript := preload("res://scripts/hotspots/HotSpotState.gd")

@export var actions: Array[Resource] = []
@export var conditions: Resource
@export var feedback: Resource

@export var states: Array[Resource] = []
@export var default_state: Resource

@export var emit_when_blocked: bool = true
@export var left_mouse_button_only: bool = true
@export var debug_print_payload: bool = false

@onready var _visual: Sprite2D = $Sprite2D
@onready var _area: Area2D = $Area2D
@onready var _event_bus: Node = get_node("/root/EventBus")
@onready var _game_state: Node = get_node("/root/GameState")

var _active_state: Resource = null


func _ready() -> void:
	if _visual:
		_visual.visible = visual_visible
		_visual.modulate = visual_modulate

	if conditions == null:
		conditions = _ConditionsScript.new()
	if feedback == null:
		feedback = _FeedbackScript.new()
	if default_state == null and _StateScript:
		# 可为空；为空则走旧的 actions/conditions/feedback
		default_state = null

	if _area:
		_area.input_event.connect(_on_area_input_event)
		# 保证能被点击拾取到
		_area.input_pickable = true

	# 监听世界状态变化，动态刷新热点可见/可交互状态
	if _game_state and _game_state.has_signal("flag_changed"):
		if not _game_state.flag_changed.is_connected(_on_state_changed):
			_game_state.flag_changed.connect(_on_state_changed)
	if _game_state and _game_state.has_signal("inventory_changed"):
		if not _game_state.inventory_changed.is_connected(_on_state_changed):
			_game_state.inventory_changed.connect(_on_state_changed)

	_refresh()


func _exit_tree() -> void:
	if _game_state and _game_state.has_signal("flag_changed") and _game_state.flag_changed.is_connected(_on_state_changed):
		_game_state.flag_changed.disconnect(_on_state_changed)
	if _game_state and _game_state.has_signal("inventory_changed") and _game_state.inventory_changed.is_connected(_on_state_changed):
		_game_state.inventory_changed.disconnect(_on_state_changed)


func _on_state_changed(_a = null, _b = null) -> void:
	_refresh()


func _get_hotspot_id() -> String:
	return hotspot_id if not hotspot_id.is_empty() else str(name)

func _get_state_priority(s: Resource) -> int:
	if s == null:
		return 0
	if s.has_method("get"):
		return int(s.get("priority"))
	return 0


func _pick_active_state() -> Resource:
	# 按 priority（高优先）-> 数组顺序（稳定）选择第一个满足 visible 条件的状态
	var candidates: Array[Resource] = []
	for s in states:
		if s != null:
			candidates.append(s)

	# stable sort by priority desc (Godot sort_custom needs callable)
	candidates.sort_custom(func(a, b): return _get_state_priority(a) > _get_state_priority(b))

	for s in candidates:
		var cond: Resource = s.get("conditions") if s.has_method("get") else null
		var visible_set: Resource = null
		if cond != null and cond.has_method("get"):
			visible_set = cond.get("visible")
		if bool(_game_state.call("check_condition_set", visible_set)):
			return s

	return default_state


func _evaluate() -> Dictionary:
	_active_state = _pick_active_state()

	var use_conditions: Resource = conditions
	if _active_state != null and _active_state.has_method("get"):
		var st_cond: Resource = _active_state.get("conditions")
		if st_cond != null:
			use_conditions = st_cond

	var visible_set: Resource = null
	var interactable_set: Resource = null
	if use_conditions != null and use_conditions.has_method("get"):
		visible_set = use_conditions.get("visible")
		interactable_set = use_conditions.get("interactable")

	var visible_ok: bool = _game_state.call("check_condition_set", visible_set)
	var interactable_ok: bool = false
	if visible_ok:
		interactable_ok = _game_state.call("check_condition_set", interactable_set)

	return {
		"visible_ok": visible_ok,
		"interactable_ok": interactable_ok,
	}


func _refresh() -> void:
	var result := _evaluate()
	visible = result.visible_ok

	# 应用状态贴图（state.texture 优先，其次 visual_texture，其次原有 sprite texture）
	if _visual:
		var tex: Texture2D = null
		if _active_state != null and _active_state.has_method("get"):
			tex = _active_state.get("texture")
		if tex == null:
			tex = visual_texture
		if tex != null:
			_visual.texture = tex

	if _area:
		# 不可见时彻底不可点；可见但不可交互时仍可点击用于“blocked 反馈”
		_area.set_deferred("monitoring", result.visible_ok)
		_area.set_deferred("input_pickable", result.visible_ok)


func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is not InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed:
		return
	if left_mouse_button_only and mb.button_index != MOUSE_BUTTON_LEFT:
		return

	var result := _evaluate()
	if not result.visible_ok:
		return

	if not result.interactable_ok and not emit_when_blocked:
		return

	var payload := _build_payload(result.visible_ok, result.interactable_ok)
	_event_bus.hotspot_action.emit(payload)

	if debug_print_payload:
		print(payload)


func _build_payload(visible_ok: bool, interactable_ok: bool) -> Dictionary:
	# state 覆盖旧 actions/feedback；未配置 state 则沿用旧字段
	var use_actions: Array = actions
	var use_feedback: Resource = feedback
	var state_id := ""
	var dialog_timeline := ""
	if _active_state != null and _active_state.has_method("get"):
		state_id = str(_active_state.get("state_id"))
		var click_tl := str(_active_state.get("click_dialog_timeline"))
		var blocked_tl := str(_active_state.get("blocked_dialog_timeline"))
		dialog_timeline = click_tl if interactable_ok else blocked_tl
		if dialog_timeline.is_empty():
			# 没配 blocked 的话，兜底用 click
			dialog_timeline = click_tl
		var st_actions: Array = _active_state.get("actions")
		if st_actions != null and st_actions.size() > 0:
			use_actions = st_actions
		var st_fb: Resource = _active_state.get("feedback")
		if st_fb != null:
			use_feedback = st_fb

	var action_dicts: Array[Dictionary] = []
	for a in use_actions:
		if a == null:
			continue
		if a.has_method("to_dict"):
			action_dicts.append(a.call("to_dict"))

	var fb: Dictionary = {}
	if use_feedback != null and use_feedback.has_method("to_dict"):
		fb = use_feedback.call("to_dict", interactable_ok)

	return {
		"hotspot_id": _get_hotspot_id(),
		"state_id": state_id,
		"dialog_timeline": dialog_timeline,
		"node_path": get_path(),
		"visible_ok": visible_ok,
		"interactable_ok": interactable_ok,
		"actions": action_dicts,
		"feedback": fb,
		"timestamp_ms": Time.get_ticks_msec(),
	}
