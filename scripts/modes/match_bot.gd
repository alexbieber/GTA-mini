class_name MatchBot
extends Player
enum Role { DEFENDER, ATTACKER, ESCORT, RECOVERER }
var participant_id := -1
var team := 0
var role := Role.ATTACKER
var manager: Node
var target_position := Vector3.ZERO
var route := PackedVector3Array()
var route_index := 0
var decision_remaining := 0.0
var attack_remaining := 0.0
var last_attacker := -1
var bot_state := "WAIT"
var last_seen := Vector3.ZERO
var memory_until := 0.0

func _ready() -> void:
	super._ready()
	remove_from_group("player")
	add_to_group("match_bots")
	collision_layer = 16
	collision_mask = 1 | 2 | 4 | 8 | 16
	var tag := Label3D.new()
	tag.text = "POLÍCIA" if team == 0 else "AURORA"
	tag.modulate = MatchArena.team_color(team)
	tag.position.y = 2.0
	tag.font_size = 24
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(tag)
	give_weapon(Arsenal.Id.RIFLE, 180)

func _build_mesh() -> void:
	var made := Models.instance_person(Models.officer_skin() if team == 0 else "res://assets/people/survivorMaleB.png")
	add_child(made.root)
	_visual = made.root
	_visual_scale = _visual.scale
	_anim = made.anim

func _physics_process(delta: float) -> void:
	if manager == null or locked or health <= 0.0:
		velocity = Vector3.ZERO
		return
	tick_combat(delta)
	decision_remaining -= delta
	attack_remaining = maxf(attack_remaining - delta, 0.0)
	if decision_remaining <= 0.0:
		decision_remaining = 0.25 + float(participant_id % 3) * 0.03
		manager.decide_bot(self)
	var direction := Vector3.ZERO
	if route_index < route.size():
		var to := route[route_index] - global_position
		to.y = 0.0
		if to.length() < 0.8:
			route_index += 1
		else:
			direction = to.normalized()
	velocity.x = direction.x * (3.0 if bot_state == "ATTACK" else 4.8)
	velocity.z = direction.z * (3.0 if bot_state == "ATTACK" else 4.8)
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	try_step(Vector3(velocity.x, 0, velocity.z) * delta)
	move_and_slide()
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-12.0 * delta))
	Models.play_move(_anim, direction.length_squared() > 0.01, true)
	if _gun:
		_gun.visible = true
		_gun.position = Vector3(0.32, 1.2, -0.4)

func move_to(at: Vector3) -> void:
	if target_position.distance_to(at) < 2.0 and route_index < route.size():
		return
	target_position = at
	route = manager.arena.route(global_position, at)
	route_index = 0
