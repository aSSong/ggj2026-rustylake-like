class_name HotSpotArea
extends Node2D

@export var hotspot_id: String = ""

## 视觉表现：在房间里直接拖拽替换热点图片
@export var visual_texture: Texture2D
@export var visual_visible: bool = true
@export var visual_modulate: Color = Color(1, 1, 1, 1)

const _StateScript := preload("res://scripts/hotspots/HotSpotState.gd")
const _ConditionsScript := preload("res://scripts/hotspots/HotSpotConditions.gd")
const _ConditionSetScript := preload("res://scripts/hotspots/HotSpotConditionSet.gd")
const _ActionScript := preload("res://scripts/hotspots/HotSpotAction.gd")
const _LifecycleScript := preload("res://scripts/hotspots/HotSpotLifecycle.gd")

enum AuthoringMode {
	ADVANCED,
	SIMPLE,
}

enum SimpleMode {
	DIALOG,
	PICKUP,
	CHANGE_ROOM,
	SET_FLAG,
	TOGGLE_FLAG,
}

@export_group("Advanced")
## 热点作者配置模式。
## - Advanced：沿用原有的 states/conditions/lifecycle 资源式配置。
## - Simple：使用下面的选择式字段，由脚本自动生成运行时状态。
@export_enum("Advanced | 使用原有资源式配置", "Simple | 使用选择式配置") var authoring_mode: int = AuthoringMode.ADVANCED
## Advanced 模式下的基础条件入口。
## 当某个 state 没有显式 conditions 时，会回退使用这里的条件。
@export var conditions: Resource
## Advanced 模式下的状态列表。
## 一般用于多状态热点、优先级切换、复杂谜题。
@export var states: Array[Resource] = []
## Advanced 模式下的兜底状态。
## 如果没有任何 state 满足 visible 条件，则会回退到这个状态。
@export var default_state: Resource
## Advanced 模式下的生命周期配置。
## 用于控制热点何时出现、何时隐藏/销毁。
@export var lifecycle: Resource

@export_group("Simple")
## Simple 模式下的交互类型。
## 根据不同模式，只需要填写对应分组里的少量字段即可。
@export_enum(
	"Dialog | 仅播放对话",
	"Pickup | 点击后获得道具",
	"Change Room | 点击后切换房间",
	"Set Flag | 点击后设置状态",
	"Toggle Flag | 点击后切换状态"
) var simple_mode: int = SimpleMode.DIALOG
## 点击成功时播放的 Dialogic timeline。
## 适用于 simple_mode = Dialog/Pickup/Change Room/Set Flag/Toggle Flag。
@export_file("*.dtl") var simple_click_dialog_timeline: String = ""
## 不满足交互条件时播放的 Dialogic timeline。
## 留空时会兜底使用 simple_click_dialog_timeline。
@export_file("*.dtl") var simple_blocked_dialog_timeline: String = ""
## Simple 单状态模式下使用的贴图。
## Toggle 模式请改用下面的 On/Off Texture。
@export var simple_texture: Texture2D
## 是否让 visible 条件与 interactable 条件保持一致。
## - true：show/hide/require/forbid/item 条件会同时控制显示和可交互。
## - false：show/hide 只控制显示，require/forbid/item 只控制可交互。
@export var simple_visible_equals_interactable: bool = true
## 需要全部满足的显示 flag。
## 只有这些 flag 全为 true 时，热点才会显示。
@export var simple_show_if_flags_all: PackedStringArray = PackedStringArray()
## 隐藏 flag 列表。
## 这些 flag 任意一个为 true 时，热点会隐藏。
@export var simple_hide_if_flags: PackedStringArray = PackedStringArray()
## 需要全部满足的可交互 flag。
## 当 simple_visible_equals_interactable = true 时，也会一起影响显示。
@export var simple_require_flags_all: PackedStringArray = PackedStringArray()
## 需要持有的道具列表。
## 用于“只有拿到某个物品后才能点击”的场景。
@export var simple_require_items: PackedStringArray = PackedStringArray()
## 禁止交互的 flag 列表。
## 这些 flag 任意一个为 true 时，热点不可交互。
@export var simple_forbid_flags: PackedStringArray = PackedStringArray()

@export_group("Simple Action")
## Pickup 模式要获得的道具 key。
## 对应 ItemDB/Inventory 里的 item_key。
@export var simple_item_key: String = ""
## Change Room 模式要跳转的 room_id。
## 取值需要存在于 SceneFlow 的房间注册表中。
@export var simple_change_room_id: String = ""
## Set Flag 模式点击后要设置的 flag 名称。
@export var simple_set_flag_name: String = ""
## Set Flag 模式写入的 flag 值。
## 一般保持 true；需要清空状态时可改为 false。
@export var simple_set_flag_value: bool = true

@export_group("Simple Toggle")
## Toggle 模式使用的 flag 名称。
## true 表示 On 状态，false 表示 Off 状态。
@export var simple_toggle_flag_name: String = ""
## Toggle 模式处于 On 状态时显示的贴图。
@export var simple_toggle_on_texture: Texture2D
## Toggle 模式处于 Off 状态时显示的贴图。
## 留空时会清空 Sprite 贴图，适合“点亮前不可见”的按钮/火焰。
@export var simple_toggle_off_texture: Texture2D
## Toggle 模式切换到 On 状态时播放的对话。
@export_file("*.dtl") var simple_toggle_on_dialog_timeline: String = ""
## Toggle 模式切换到 Off 状态时播放的对话。
@export_file("*.dtl") var simple_toggle_off_dialog_timeline: String = ""

@export_group("Simple Lifecycle")
## 生成条件：这些 flag 全满足后，热点才允许出现。
## 留空表示默认出生即存在。
@export var simple_spawn_flags_all: PackedStringArray = PackedStringArray()
## 销毁条件：这些 flag 全满足后，热点会隐藏或释放。
@export var simple_destroy_flags_all: PackedStringArray = PackedStringArray()
## 生命周期命中后的处理方式。
## - Hide：仅隐藏，节点仍保留。
## - Free：直接 queue_free。
@export_enum("Hide | 仅隐藏", "Free | 直接释放节点") var simple_destroy_mode: int = 1

@export_group("Interaction")
## 当热点可见但不可交互时，是否仍然发出点击事件。
## 打开后可以配合 blocked_dialog_timeline 做“被锁住”的提示。
@export var emit_when_blocked: bool = true
## 是否只响应鼠标左键。
## 关掉后，右键等其他鼠标键也能触发点击。
@export var left_mouse_button_only: bool = true
## 是否在输出窗口打印热点 payload。
## 适合调试当前热点最终发出的对话、动作和状态。
@export var debug_print_payload: bool = false

@onready var _visual: Sprite2D = $Sprite2D
@onready var _area: Area2D = $Area2D
@onready var _event_bus: Node = get_node("/root/EventBus")
@onready var _game_state: Node = get_node("/root/GameState")

var _active_state: Resource = null
var _simple_states: Array[Resource] = []
var _simple_default_state: Resource = null
var _simple_lifecycle: Resource = null


func _ready() -> void:
	if _visual:
		_visual.visible = visual_visible
		_visual.modulate = visual_modulate

	if _is_simple_authoring():
		_rebuild_simple_authoring_resources()

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


func _is_simple_authoring() -> bool:
	return int(authoring_mode) == AuthoringMode.SIMPLE


func _rebuild_simple_authoring_resources() -> void:
	_simple_states.clear()
	_simple_default_state = null
	_simple_lifecycle = _build_simple_lifecycle()

	match int(simple_mode):
		SimpleMode.TOGGLE_FLAG:
			_build_simple_toggle_states()
		_:
			var single_state := _build_simple_single_state()
			if single_state != null:
				_simple_states.append(single_state)
				_simple_default_state = single_state


func _get_effective_states() -> Array[Resource]:
	if _is_simple_authoring():
		return _simple_states
	return states


func _get_effective_default_state() -> Resource:
	if _is_simple_authoring():
		return _simple_default_state
	return default_state


func _get_effective_lifecycle() -> Resource:
	if _is_simple_authoring():
		return _simple_lifecycle
	return lifecycle


func _get_state_conditions(state: Resource) -> Resource:
	if state != null and state.has_method("get"):
		var state_conditions: Resource = state.get("conditions")
		if state_conditions != null:
			return state_conditions
	return conditions


func _build_simple_single_state() -> Resource:
	var visible_set := _build_simple_visible_condition_set()
	var interactable_set := _build_simple_interactable_condition_set(visible_set, simple_show_if_flags_all, simple_hide_if_flags)
	var state_conditions := _new_conditions(visible_set, interactable_set)
	return _new_state(
		"simple",
		state_conditions,
		simple_texture,
		simple_click_dialog_timeline,
		simple_blocked_dialog_timeline,
		_build_simple_actions_for_mode(),
		false
	)


func _build_simple_toggle_states() -> void:
	var flag_name := simple_toggle_flag_name.strip_edges()
	if flag_name.is_empty():
		return

	var on_visible_all := _merge_flags(simple_show_if_flags_all, PackedStringArray([flag_name]))
	var on_visible_forbids := simple_hide_if_flags
	var on_visible_set := _build_simple_visible_condition_set(on_visible_all, on_visible_forbids)
	var on_interactable_set := _build_simple_interactable_condition_set(on_visible_set, on_visible_all, on_visible_forbids)
	var on_state := _new_state(
		"toggle_on",
		_new_conditions(on_visible_set, on_interactable_set),
		simple_toggle_on_texture,
		simple_toggle_on_dialog_timeline,
		simple_blocked_dialog_timeline,
		[_new_action(_ActionScript.ActionType.CLEAR_FLAG, {"name": flag_name})],
		false
	)

	var off_visible_all := simple_show_if_flags_all
	var off_visible_forbids := _merge_flags(simple_hide_if_flags, PackedStringArray([flag_name]))
	var off_visible_set := _build_simple_visible_condition_set(off_visible_all, off_visible_forbids)
	var off_interactable_set := _build_simple_interactable_condition_set(off_visible_set, off_visible_all, off_visible_forbids)
	var off_state := _new_state(
		"toggle_off",
		_new_conditions(off_visible_set, off_interactable_set),
		simple_toggle_off_texture,
		simple_toggle_off_dialog_timeline,
		simple_blocked_dialog_timeline,
		[_new_action(_ActionScript.ActionType.SET_FLAG, {"name": flag_name, "value": true})],
		simple_toggle_off_texture == null
	)

	_simple_states = [on_state, off_state]
	_simple_default_state = off_state


func _build_simple_actions_for_mode() -> Array[Resource]:
	var out: Array[Resource] = []
	match int(simple_mode):
		SimpleMode.PICKUP:
			if not simple_item_key.is_empty():
				out.append(_new_action(_ActionScript.ActionType.PICKUP, {
					"item_key": simple_item_key,
					"fly": true,
				}))
		SimpleMode.CHANGE_ROOM:
			if not simple_change_room_id.is_empty():
				out.append(_new_action(_ActionScript.ActionType.CHANGE_ROOM, {
					"room_id": simple_change_room_id,
				}))
		SimpleMode.SET_FLAG:
			if not simple_set_flag_name.is_empty():
				out.append(_new_action(_ActionScript.ActionType.SET_FLAG, {
					"name": simple_set_flag_name,
					"value": simple_set_flag_value,
				}))
	return out


func _build_simple_visible_condition_set(extra_requires_all: PackedStringArray = PackedStringArray(), extra_forbids: PackedStringArray = PackedStringArray()) -> Resource:
	var requires_all := _merge_flags(simple_show_if_flags_all, extra_requires_all)
	var forbids := _merge_flags(simple_hide_if_flags, extra_forbids)
	var requires_items := PackedStringArray()
	if simple_visible_equals_interactable:
		requires_all = _merge_flags(requires_all, simple_require_flags_all)
		forbids = _merge_flags(forbids, simple_forbid_flags)
		requires_items = simple_require_items
	return _new_condition_set(requires_all, requires_items, forbids)


func _build_simple_interactable_condition_set(visible_set: Resource, visible_requires_all: PackedStringArray, visible_forbids: PackedStringArray) -> Resource:
	if simple_visible_equals_interactable:
		return visible_set
	var requires_all := _merge_flags(visible_requires_all, simple_require_flags_all)
	var forbids := _merge_flags(visible_forbids, simple_forbid_flags)
	return _new_condition_set(requires_all, simple_require_items, forbids)


func _build_simple_lifecycle() -> Resource:
	if simple_spawn_flags_all.is_empty() and simple_destroy_flags_all.is_empty():
		return null
	var life := _LifecycleScript.new()
	life.enabled = true
	life.spawn_conditions = _new_condition_set(simple_spawn_flags_all, PackedStringArray(), PackedStringArray())
	life.destroy_conditions = _new_condition_set(simple_destroy_flags_all, PackedStringArray(), PackedStringArray())
	life.destroy_mode = simple_destroy_mode as _LifecycleScript.DestroyMode
	return life


func _new_condition_set(requires_all: PackedStringArray, requires_items: PackedStringArray, forbids: PackedStringArray) -> Resource:
	var condition_set := _ConditionSetScript.new()
	condition_set.requires_flags_all = requires_all
	condition_set.requires_items = requires_items
	condition_set.forbids_flags = forbids
	return condition_set


func _new_conditions(visible_set: Resource, interactable_set: Resource) -> Resource:
	var state_conditions := _ConditionsScript.new()
	state_conditions.visible = visible_set
	state_conditions.interactable = interactable_set
	return state_conditions


func _new_action(action_type: int, params: Dictionary) -> Resource:
	var action := _ActionScript.new()
	action.type = action_type as _ActionScript.ActionType
	action.params = params.duplicate(true)
	return action


func _new_state(
	state_id: String,
	state_conditions: Resource,
	texture: Texture2D,
	click_dialog_timeline: String,
	blocked_dialog_timeline: String,
	state_actions: Array,
	clear_when_null: bool
) -> Resource:
	var state := _StateScript.new()
	state.state_id = state_id
	state.conditions = state_conditions
	state.texture = texture
	state.click_dialog_timeline = click_dialog_timeline
	state.blocked_dialog_timeline = blocked_dialog_timeline
	state.actions = state_actions
	state.clear_texture_when_null = clear_when_null
	if state_id.contains("toggle_on"):
		state.priority = 10
	return state


func _merge_flags(a: PackedStringArray, b: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for entry in a:
		if not out.has(entry):
			out.append(entry)
	for entry in b:
		if not out.has(entry):
			out.append(entry)
	return out

func _get_state_priority(s: Resource) -> int:
	if s == null:
		return 0
	if s.has_method("get"):
		return int(s.get("priority"))
	return 0


func _pick_active_state() -> Resource:
	# 按 priority（高优先）-> 数组顺序（稳定）选择第一个满足 visible 条件的状态
	var candidates: Array[Resource] = []
	for s in _get_effective_states():
		if s != null:
			candidates.append(s)

	# stable sort by priority desc (Godot sort_custom needs callable)
	candidates.sort_custom(func(a, b): return _get_state_priority(a) > _get_state_priority(b))

	for s in candidates:
		var cond := _get_state_conditions(s)
		var visible_set: Resource = null
		if cond != null and cond.has_method("get"):
			visible_set = cond.get("visible")
		if bool(_game_state.call("check_condition_set", visible_set)):
			return s

	return _get_effective_default_state()

func _lifecycle_allows() -> Dictionary:
	# 默认允许
	var use_lifecycle := _get_effective_lifecycle()
	if use_lifecycle == null or not use_lifecycle.has_method("get") or not bool(use_lifecycle.get("enabled")):
		return {"spawn_ok": true, "destroy_now": false, "destroy_mode": 0}

	var spawn_set: Resource = use_lifecycle.get("spawn_conditions")
	var destroy_set: Resource = use_lifecycle.get("destroy_conditions")
	var destroy_mode := int(use_lifecycle.get("destroy_mode"))

	var spawn_ok := bool(_game_state.call("check_condition_set", spawn_set))
	var destroy_now := bool(_game_state.call("check_condition_set", destroy_set))

	return {"spawn_ok": spawn_ok, "destroy_now": destroy_now, "destroy_mode": destroy_mode}


func _evaluate() -> Dictionary:
	var life := _lifecycle_allows()
	if bool(life.destroy_now):
		return {"visible_ok": false, "interactable_ok": false, "destroy_now": true, "destroy_mode": int(life.destroy_mode)}
	if not bool(life.spawn_ok):
		return {"visible_ok": false, "interactable_ok": false, "destroy_now": false, "destroy_mode": int(life.destroy_mode)}

	_active_state = _pick_active_state()

	var use_conditions := _get_state_conditions(_active_state)

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
		"destroy_now": false,
		"destroy_mode": int(life.destroy_mode),
	}


func _refresh() -> void:
	var result := _evaluate()
	if bool(result.get("destroy_now", false)):
		# 生命周期触发销毁/隐藏
		var dm := int(result.get("destroy_mode", 0))
		if dm == 1: # FREE
			queue_free()
			return
		visible = false
		if _area:
			_area.set_deferred("monitoring", false)
			_area.set_deferred("input_pickable", false)
		return

	visible = bool(result.visible_ok)

	# 应用状态贴图（state.texture 优先，其次 visual_texture，其次原有 sprite texture）
	if _visual:
		var has_state := _active_state != null and _active_state.has_method("get")
		var state_tex: Texture2D = null
		var clear_when_null := false
		if has_state:
			state_tex = _active_state.get("texture")
			# HotSpotState.clear_texture_when_null（duck-typing）
			clear_when_null = bool(_active_state.get("clear_texture_when_null"))

		if has_state and state_tex == null and clear_when_null:
			_visual.texture = null
		else:
			var tex: Texture2D = state_tex
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
	# 仅使用 state 配置（默认字段已移除）
	var use_actions: Array = []
	var use_feedback: Resource = null
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
