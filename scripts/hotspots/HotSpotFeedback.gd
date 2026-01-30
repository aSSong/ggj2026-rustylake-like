class_name HotSpotFeedback
extends Resource

## 只描述“应该反馈什么”，不在 HotSpotArea 里直接播放/抖动；
## 由 EventBus 监听方（UI/RoomController）统一执行。

@export var click_sfx: AudioStream
@export_multiline var click_prompt: String = ""

@export var blocked_sfx: AudioStream
@export_multiline var blocked_prompt: String = ""

@export var shake_on_click: bool = false
@export var shake_on_blocked: bool = false
@export var shake_strength: float = 8.0
@export var shake_duration: float = 0.15


func to_dict(interactable_ok: bool) -> Dictionary:
	var sfx: AudioStream = click_sfx if interactable_ok else blocked_sfx
	var prompt: String = click_prompt if interactable_ok else blocked_prompt

	return {
		"interactable_ok": interactable_ok,
		# 直接传资源引用，监听方可自行播放；也可以后续改成资源路径字符串。
		"sfx": sfx,
		"prompt": prompt,
		"shake": (shake_on_click if interactable_ok else shake_on_blocked),
		"shake_strength": shake_strength,
		"shake_duration": shake_duration,
	}
