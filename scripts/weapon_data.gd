class_name WeaponData
extends Resource
## Original tunable weapon data. Arsenal retains the legacy shop API.
@export var label := "PISTOL"
@export var damage := 22.0
@export var effective_range := 70.0
@export var shot_interval := 0.28
@export var magazine_size := 12
@export var starting_ammo := 36
@export var reload_seconds := 1.5
@export var spread := 0.012
@export var ads_spread_multiplier := 0.25
@export var moving_spread_multiplier := 1.7
@export var recoil_vertical := 0.022
@export var recoil_horizontal := 0.006
@export var aim_seconds := 0.18
@export var mobility := 1.0
@export var head_multiplier := 2.0
@export var limb_multiplier := 0.75
@export var automatic := false
@export var price := 250
@export_range(0.0, 1.0) var minimum_damage_ratio := 0.55
@export var falloff_start := 0.0
@export_range(1, 16) var pellet_count := 1

func damage_at(distance: float) -> float:
	if distance > effective_range: return 0.0
	var start := falloff_start if falloff_start > 0.0 else effective_range * 0.45
	var weight := clampf((distance - start) / maxf(effective_range - start, 0.01), 0.0, 1.0)
	return damage * lerpf(1.0, minimum_damage_ratio, weight)

func as_dictionary() -> Dictionary:
	return {"name": label, "dmg": damage, "range": effective_range,
		"rate": shot_interval, "spread": spread, "ammo": starting_ammo, "price": price}
