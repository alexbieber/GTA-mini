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
var difficulty: BotDifficulty = preload("res://resources/ai/normal.tres")
var brain := BotBrain.new()
var navigation_agent: NavigationAgent3D
var navigation_steps := 0
var _navigation_goal := false

func set_difficulty(preset: String) -> void:
	difficulty = load("res://resources/ai/%s.tres" % (preset if preset in ["easy", "normal", "hard"] else "normal")) as BotDifficulty

func can_perceive(actor: Node3D, sight_position: Vector3) -> bool:
	if actor == self or not is_instance_valid(actor): return false
	var from := global_position + Vector3.UP * 1.3
	var offset := sight_position - from
	if offset.length() > difficulty.sight_range: return false
	var horizontal := Vector3(offset.x, 0, offset.z)
	if horizontal.length_squared() > 0.01 and (-global_basis.z).dot(horizontal.normalized()) < cos(deg_to_rad(difficulty.field_of_view * 0.5)): return false
	var query := PhysicsRayQueryParameters3D.create(from, sight_position, 1 | 2 | 4 | 8 | 16, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == actor

func observe_enemy(id: int, at: Vector3) -> void:
	brain.observe(self, id, at)

func hear_sound(at: Vector3, shooter_id: int, hearing_distance := 45.0) -> bool:
	return brain.hear(self, at, shooter_id, hearing_distance)

func reacted() -> bool:
	return manager != null and manager.rules.elapsed >= brain.reaction_until

func _ready() -> void:
	super._ready()
	remove_from_group("player")
	add_to_group("match_bots")
	if manager and manager.arena:
		GridNavigation.ensure_region(manager.arena)
	navigation_agent = NavigationAgent3D.new()
	navigation_agent.path_desired_distance = 0.7
	navigation_agent.target_desired_distance = 0.75
	navigation_agent.radius = 0.34
	navigation_agent.avoidance_enabled = false
	navigation_agent.path_max_distance = 2.5
	navigation_agent.path_search_max_polygons = difficulty.navigation_search_polygons
	add_child(navigation_agent)
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
		decision_remaining = difficulty.decision_interval + float(participant_id % 3) * 0.03
		if not brain.plan(self):
			manager.decide_bot(self)
			brain.sync_objective_state(bot_state)
	var direction := Vector3.ZERO
	if route.is_empty(): _navigation_goal = false
	var map_ready := navigation_agent and NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) > 0
	if _navigation_goal and map_ready:
		var next := navigation_agent.get_next_path_position()
		navigation_steps += 1
		var to := next - global_position
		to.y = 0.0
		if navigation_agent.is_navigation_finished():
			route_index = route.size()
			_navigation_goal = false
		else:
			direction = to.normalized()
	elif route_index < route.size():
		var to := route[route_index] - global_position
		to.y = 0.0
		if to.length() < 0.8:
			route_index += 1
		else:
			direction = to.normalized()
	var speed := difficulty.combat_speed if bot_state == "ATTACK" else difficulty.walk_speed
	velocity.x = move_toward(velocity.x, direction.x * speed, 24.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 24.0 * delta)
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	try_step(Vector3(velocity.x, 0, velocity.z) * delta)
	move_and_slide()
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-12.0 * delta))
	Models.play_move(_anim, direction.length_squared() > 0.01, true)
	if _gun:
		_gun.visible = weapon != Arsenal.Id.NONE and plate_remaining <= 0.0
		_gun.position = Vector3(0.32, 1.2, -0.4)

func move_to(at: Vector3) -> void:
	if target_position.distance_to(at) < 2.0 and route_index < route.size():
		return
	target_position = at
	route = manager.arena.route(global_position, at)
	route_index = 0
	if navigation_agent:
		navigation_agent.target_position = manager.arena.nearest_clear(at)
		_navigation_goal = true
