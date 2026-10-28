class_name HealthComponent
extends RefCounted

signal damaged(amount: float)
signal died
@export var maximum := 100.0
var current := 100.0
var armor := 0.0
var armor_first := false
var regeneration_delay := 0.0
var regeneration_per_second := 0.0
var _since_damage := 0.0

func apply_damage(amount: float, multiplier := 1.0, bypass_armor := false) -> float:
	if current <= 0.0 or amount <= 0.0:
		return 0.0
	var incoming := maxf(amount * multiplier, 0.0)
	var absorbed := 0.0 if bypass_armor else minf(armor, incoming * (1.0 if armor_first else 0.6))
	armor -= absorbed
	_since_damage = 0.0
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
	armor = 0.0
	_since_damage = 0.0

func tick(delta: float) -> void:
	if current <= 0.0 or regeneration_per_second <= 0.0:
		return
	var previous := _since_damage
	_since_damage += maxf(delta, 0.0)
	# Only the part of this tick beyond the grace period heals.
	var healing_seconds := maxf(_since_damage - regeneration_delay, 0.0) - maxf(previous - regeneration_delay, 0.0)
	heal(healing_seconds * regeneration_per_second)
