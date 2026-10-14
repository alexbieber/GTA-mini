class_name LootConfig
extends Resource
@export_range(12, 64) var count := 24
## Repeated entries act as weights: 0 weapon, 1 ammo, 2 armor, 3 recovery.
@export var distribution: Array[int] = [0, 1, 2, 3]
@export var weapons: Array[int] = [3, 1, 2]
@export var weapon_rounds := 60
@export var ammo_rounds := 36
@export var armor_amount := 40.0
@export var heal_amount := 40.0
