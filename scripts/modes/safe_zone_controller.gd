class_name SafeZoneController
extends RefCounted
signal event(name: String, payload: Dictionary)
signal damage_tick(amount: float)
var config := SafeZoneConfig.new()
var center := Vector3.ZERO
var radius := 84.0
var phase := 0
var closing := false
var finished := false
var remaining := 0.0
var next_center := Vector3.ZERO
var next_radius := 84.0
var _start_center := Vector3.ZERO
var _start_radius := 84.0
var _damage_accumulator := 0.0
var validator: Callable
var rng := RandomNumberGenerator.new()

func reset(at: Vector3, valid: Callable = Callable()) -> void:
	center = at
	radius = config.initial_radius
	phase = 0
	closing = false
	finished = false
	remaining = maxf(config.waits[0], 0.01)
	_damage_accumulator = 0.0
	validator = valid
	rng.seed = 420
	choose_next()

func choose_next() -> void:
	next_radius = maxf(config.initial_radius * config.ratios[phase], 1.0)
	next_radius = minf(next_radius, radius)
	next_center = center
	for i in 24:
		var angle := rng.randf_range(0, TAU)
		var offset := rng.randf_range(0.0, maxf(radius - next_radius, 0.0) * 0.8)
		var proposed := center + Vector3(cos(angle), 0, sin(angle)) * offset
		if not validator.is_valid() or validator.call(proposed):
			next_center = proposed
			break

func tick(delta: float) -> void:
	_damage_accumulator += delta
	# Damage uses one-second quanta independent of render/physics rate.
	while _damage_accumulator >= 1.0:
		_damage_accumulator -= 1.0
		damage_tick.emit(config.damage_per_second * (1.0 + float(phase) * 0.35))
	var left := delta
	while left > 0.0 and not finished:
		var step := minf(left, remaining)
		remaining -= step
		left -= step
		if closing:
			var duration := maxf(config.closures[phase], 0.01)
			var weight := clampf(1.0 - remaining / duration, 0.0, 1.0)
			center = _start_center.lerp(next_center, weight)
			radius = lerpf(_start_radius, next_radius, weight)
		if remaining > 0.00001:
			break
		if not closing:
			closing = true
			_start_center = center
			_start_radius = radius
			remaining = maxf(config.closures[phase], 0.01)
			event.emit("ZONE_SHRINKING", {"phase": phase})
			if phase == config.ratios.size() - 1:
				event.emit("FINAL_CIRCLE", {})
		else:
			phase += 1
			if phase >= config.ratios.size():
				finished = true
				phase = config.ratios.size() - 1
				remaining = 0.0
			else:
				closing = false
				remaining = maxf(config.waits[phase], 0.01)
				choose_next()

func contains(at: Vector3) -> bool:
	return Vector2(at.x - center.x, at.z - center.z).length() <= radius

func snapshot() -> Dictionary:
	return {"center": center, "radius": radius, "next_center": next_center, "next_radius": next_radius,
		"phase": phase, "remaining": remaining, "closing": closing, "finished": finished}
