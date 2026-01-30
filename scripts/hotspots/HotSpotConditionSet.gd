class_name HotSpotConditionSet
extends Resource

## 你给的条件字段规范：
## - requires_flags_all: ["drawer_opened"]
## - requires_flags_any: ["lamp_on", "match_used"]
## - requires_items: ["small_key"]
## - forbids_flags: ["ghost_defeated"]

@export var requires_flags_all: PackedStringArray = PackedStringArray()
@export var requires_flags_any: PackedStringArray = PackedStringArray()
@export var requires_items: PackedStringArray = PackedStringArray()
@export var forbids_flags: PackedStringArray = PackedStringArray()
