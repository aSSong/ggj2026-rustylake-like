class_name HotSpotLifecycle
extends Resource

## HotSpot 生命周期控制（可选）：
## - spawn_conditions：满足后才允许出现（否则隐藏且不可点）
## - destroy_conditions：满足后销毁/隐藏，并且在房间重新进入时也会再次判定（所以“不会再创建”可通过永久 flag 实现）

enum DestroyMode {
	HIDE,
	FREE,
}

@export var enabled: bool = true
@export var spawn_conditions: Resource
@export var destroy_conditions: Resource
@export var destroy_mode: DestroyMode = DestroyMode.FREE

