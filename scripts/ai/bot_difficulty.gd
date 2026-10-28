class_name BotDifficulty
extends Resource
## All AI tuning is shared through immutable preset resources.
@export var label := "Normal"
@export_range(30.0, 180.0) var field_of_view := 110.0
@export var sight_range := 42.0
@export var hearing_range := 38.0
@export var memory_seconds := 5.0
@export var decision_interval := 0.28
@export var reaction_seconds := 0.25
@export_range(0.0, 1.0) var accuracy := 0.70
@export var fire_interval := 0.65
@export var damage_multiplier := 1.0
@export var walk_speed := 4.8
@export var combat_speed := 3.0
@export var retreat_health_ratio := 0.28
@export var cover_search_radius := 14.0
@export var navigation_search_polygons := 20000
