class_name HotSpotConditions
extends Resource

## 用两套条件分别控制：
## - visible：出现/显示条件（不满足则隐藏且不可点）
## - interactable：可交互条件（不满足则走“不可用反馈”，是否仍派发事件由 HotSpotArea 控制）

const _ConditionSetScript := preload("res://scripts/hotspots/HotSpotConditionSet.gd")

@export var visible: Resource
@export var interactable: Resource


func _init() -> void:
	if visible == null:
		visible = _ConditionSetScript.new()
	if interactable == null:
		interactable = _ConditionSetScript.new()
