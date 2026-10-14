class_name HealthComponent
extends RefCounted

signal damaged(amount: float)
signal died
@export var maximum := 100.0
var current := 100.0
var armor := 0.0

func apply_damage(amount: float, multiplier := 1.0) -> float:
	if current <= 0.0 or amount <= 0.0:
		return 0.0
	var incoming := maxf(amount * multiplier, 0.0)
	var absorbed := minf(armor, incoming * 0.6)
	armor -= absorbed
	var applied := minf(current, incoming - absorbed)
	current -= applied
	damaged.emit(applied)
	if current <= 0.0:
		died.emit()
	return applied

func heal(amount: float) -> void:
	if current > 0.0:
		current = clampf(current + maxf(amount, 0.0), 0.0, maximum)

func reset() -> void:
	current = maximum
