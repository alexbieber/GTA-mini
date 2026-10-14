class_name LanRemotePlayer
extends Player
## Server-owned body. Only intent is received; collision, stamina and velocity stay local.
var move_intent := Vector2.ZERO
var view_yaw := 0.0
var view_pitch := 0.0
var sprint_intent := false
var aim_intent := false
var fire_intent := false
var last_input_ms := 0

func _ready() -> void:
	super._ready()
	remove_from_group("player")
	collision_layer = 16
	collision_mask = 1 | 2 | 4 | 8 | 16

func _move_input() -> Vector2:
	return move_intent

func control_yaw() -> float:
	return view_yaw

func _physics_process(delta: float) -> void:
	_update_skin()
	if Time.get_ticks_msec() - last_input_ms > 500:
		move_intent = Vector2.ZERO
		fire_intent = false
		sprint_intent = false
	if locked or health <= 0.0:
		velocity = Vector3.ZERO
		reset_combat()
		return
	tick_combat(delta)
	if vault_remaining > 0.0:
		_tick_mantle(delta)
		return
	slide_cooldown = maxf(slide_cooldown - delta, 0.0)
	tactical_cooldown = maxf(tactical_cooldown - delta, 0.0)
	tactical_remaining = maxf(tactical_remaining - delta, 0.0)
	aiming = aim_intent and weapon != Arsenal.Id.NONE and slide_remaining <= 0.0 and plate_remaining <= 0.0
	if aiming: tactical_remaining = 0.0
	if in_cover and not Cover.retains_contact(self, _cover_normal): exit_cover()
	if in_cover and _cover_low: set_crouched(not aiming)
	var grounded := is_on_floor()
	if locomotion.tick(delta, grounded): velocity.y = Movement.JUMP_SPEED
	elif not grounded: velocity.y -= GRAVITY * delta
	else: velocity.y = 0.0
	var direction := Basis(Vector3.UP, view_yaw) * Vector3(move_intent.x, 0.0, move_intent.y)
	if in_cover:
		if direction.dot(_cover_normal) > 0.55: exit_cover()
		else:
			var tangent := _cover_normal.cross(Vector3.UP).normalized()
			direction = tangent * direction.dot(tangent)
	var want_sprint := (sprint_intent or tactical_remaining > 0.0) and stamina > 4.0 and not aiming and not crouched and not in_cover and reload_remaining <= 0.0 and plate_remaining <= 0.0 and _sprint_block_remaining <= 0.0
	sprinting = want_sprint and direction.length_squared() > 0.05
	stamina = clampf(stamina + (-18.0 if sprinting else 12.0) * delta, 0.0, 100.0)
	var speed := SPRINT_SPEED if sprinting else WALK_SPEED
	if weapon != Arsenal.Id.NONE: speed *= Arsenal.data(weapon).mobility
	if crouched: speed = 2.4
	elif aiming: speed *= 0.55
	elif sprinting and tactical_remaining > 0.0: speed *= 1.3
	if slide_remaining > 0.0:
		slide_remaining = maxf(slide_remaining - delta, 0.0)
		direction = _slide_direction
		speed = lerpf(3.0, 10.0, slide_remaining / 0.65)
	var acceleration := tactical.acceleration if tactical else 26.0
	if direction.length_squared() < 0.01: acceleration = tactical.deceleration if tactical else 34.0
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	try_step(Vector3(velocity.x, 0.0, velocity.z) * delta)
	move_and_slide()
	rotation.y = view_yaw
	Models.play_move(_anim, grounded and direction.length_squared() > 0.05, sprinting)
	movement_state = "Crouch" if crouched else ("Sprint" if sprinting else "Jog")
	if reload_remaining > 0.0: movement_state = "Reload"
	if _visual: _visual.scale.y = lerpf(_visual.scale.y, _visual_scale.y * (0.65 if crouched else 1.0), 1.0 - exp(-16.0 * delta))
	if _gun:
		_gun.visible = weapon != Arsenal.Id.NONE and plate_remaining <= 0.0
		_gun.position = Vector3(0.32, 0.82 if crouched else 1.22, -0.38)
		_gun.rotation.x = view_pitch

func request_jump() -> void:
	super.request_jump()

