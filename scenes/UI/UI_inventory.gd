extends CanvasLayer

@export var slot_size: Vector2 = Vector2(90, 90)
@export var selected_tint: Color = Color(1, 1, 1, 1)
@export var unselected_tint: Color = Color(0.8, 0.8, 0.8, 1)

@export var gain_fly_duration: float = 0.45

@export var debug_add_test_item_on_start: bool = false
@export var debug_test_item_key: String = "test_key"

@onready var _inventory: Node = get_node("/root/Inventory")
@onready var _item_db: Node = get_node("/root/ItemDB")
@onready var _game_state: Node = get_node("/root/GameState")

@onready var _fx_layer: Control = $Control/FxLayer
@onready var _slots: HBoxContainer = $Control/Bar/Scroll/Slots
@onready var _scroll: ScrollContainer = $Control/Bar/Scroll
@onready var _popup: PopupPanel = $Control/ItemPopup
@onready var _popup_image: TextureRect = $Control/ItemPopup/Panel/VBox/InspectImage
@onready var _popup_name: Label = $Control/ItemPopup/Panel/VBox/Name
@onready var _popup_desc: RichTextLabel = $Control/ItemPopup/Panel/VBox/Desc

var _buttons_by_key: Dictionary = {} # String -> TextureButton


func _ready() -> void:
	# 避免 PopupPanel 初始闪现
	_popup.hide()

	if debug_add_test_item_on_start:
		_inventory.call("add_item", debug_test_item_key)

	if _inventory.has_signal("item_added"):
		if not _inventory.item_added.is_connected(_refresh):
			_inventory.item_added.connect(_refresh)
	if _inventory.has_signal("item_removed"):
		if not _inventory.item_removed.is_connected(_refresh):
			_inventory.item_removed.connect(_refresh)
	if _inventory.has_signal("selection_changed"):
		if not _inventory.selection_changed.is_connected(_update_selection_visuals):
			_inventory.selection_changed.connect(_update_selection_visuals)
	if _game_state.has_signal("inventory_changed"):
		if not _game_state.inventory_changed.is_connected(_refresh):
			_game_state.inventory_changed.connect(_refresh)

	_refresh()


func _refresh(_a = null, _b = null) -> void:
	for c in _slots.get_children():
		c.queue_free()
	_buttons_by_key.clear()

	var keys: Array = _inventory.call("get_items")
	for k in keys:
		var key := str(k)
		var item: Resource = _item_db.call("get_item", key)
		if item == null:
			continue

		var btn := TextureButton.new()
		btn.name = "Item_%s" % key
		btn.custom_minimum_size = slot_size
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		btn.toggle_mode = true
		btn.texture_normal = item.get("icon")
		btn.pressed.connect(_on_item_pressed.bind(key))
		_slots.add_child(btn)
		_buttons_by_key[key] = btn

	_update_selection_visuals(_inventory.call("get_selected_key"))


func _update_selection_visuals(_selected = null) -> void:
	var selected_key := str(_inventory.call("get_selected_key"))
	for k in _buttons_by_key.keys():
		var btn: TextureButton = _buttons_by_key[k]
		var is_sel := (str(k) == selected_key)
		btn.button_pressed = is_sel
		btn.modulate = selected_tint if is_sel else unselected_tint


func _on_item_pressed(key: String) -> void:
	_inventory.call("select_item", key)
	_show_item_popup(key)


func _show_item_popup(key: String) -> void:
	var item: Resource = _item_db.call("get_item", key)
	if item == null:
		return

	var tex: Texture2D = item.get("inspect_image")
	if tex == null:
		tex = item.get("icon")

	_popup_image.texture = tex
	_popup_name.text = str(item.get("display_name"))
	_popup_desc.text = str(item.get("description"))

	_popup.popup_centered()


func play_item_gain_fly(item_key: String, from_world_pos: Vector2) -> void:
	# 动画结束后由调用方再真正 add_item（这样“飞到格子后才显示获得”）。
	var item: Resource = _item_db.call("get_item", item_key)
	if item == null:
		return

	var icon: Texture2D = item.get("icon")
	if icon == null:
		return

	var idx := int((_inventory.call("get_items") as Array).size())
	var sep := 12.0
	if _slots.has_theme_constant_override("separation"):
		sep = float(_slots.get_theme_constant("separation"))
	var scroll_rect := _scroll.get_global_rect()
	var to_pos := Vector2(
		scroll_rect.position.x + 10.0 + float(idx) * (slot_size.x + sep),
		scroll_rect.position.y + (scroll_rect.size.y - slot_size.y) * 0.5
	)

	var from_pos := from_world_pos - slot_size * 0.5

	var fx := TextureRect.new()
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.custom_minimum_size = slot_size
	fx.size = slot_size
	fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fx.texture = icon
	fx.position = from_pos
	_fx_layer.add_child(fx)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fx, "position", to_pos, gain_fly_duration)
	tween.finished.connect(fx.queue_free)

	await tween.finished

