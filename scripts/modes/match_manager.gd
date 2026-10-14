class_name MatchManager
extends Node
## Composition adapter. Rules hold serializable state; this node owns local actors.
var game: Node3D
var rules := MatchRules.new()
var bus := MatchEventBus.new()
var announcer := AnnouncerManager.new()
var arena: MatchArena
var zone: SafeZoneController
var actors: Dictionary = {}
var _last_damage: Dictionary = {}
var _free_state: Dictionary = {}
var _ambient: Array[Dictionary] = []
var _loot: Array[Dictionary] = []
var _zone_visual_remaining := 0.0
var _last_player_announced := false
var _resume_phase := -1
var loot_config := LootConfig.new()
var player_team := 1
var _melee_cooldowns: Dictionary = {}
var tactical_config: TacticalConfig = preload("res://resources/tactical_default.tres")
var _pickup_remaining := 0.0

func _ready() -> void:
	rules.config = load("res://resources/match_default.tres") as MatchConfig
	loot_config = load("res://resources/loot_default.tres") as LootConfig
	add_child(bus)
	add_child(announcer)
	rules.event.connect(bus.publish)
	bus.occurred.connect(announcer.on_event)
	bus.occurred.connect(_on_event)

func competitive() -> bool:
	return arena != null and rules.mode != MatchRules.Mode.FREE

func _save_free() -> void:
	if game.get("competitive_only") == true: return
	if not _free_state.is_empty():
		return
	var p: Player = game.player
	var position: Vector3 = game._tracked().global_position
	if p.in_vehicle:
		position += Vector3(2, 0.2, 0)
	_free_state = {"position": position, "health": p.health, "stamina": p.stamina,
		"weapon": p.weapon, "owned": p.owned_weapons.duplicate(), "ammo": p.ammo.duplicate(),
		"magazines": p.magazines.duplicate(), "armor": p.vitality.armor,
		"phase": game.Phase.STEAL if game.phase == game.Phase.TITLE else game.phase}

func _restore_free() -> void:
	if game.get("competitive_only") == true: return
	if _free_state.is_empty():
		return
	var p: Player = game.player
	p.global_position = _free_state.position
	p.health = _free_state.health
	p.stamina = _free_state.stamina
	p.weapon = _free_state.weapon
	p.owned_weapons.assign(_free_state.owned)
	p.ammo = _free_state.ammo.duplicate()
	p.magazines = _free_state.magazines.duplicate()
	p.configure_tactical(null)
	p.vitality.armor = _free_state.armor
	game.phase = _free_state.phase
	_free_state.clear()

func _cleanup() -> void:
	game._firing = false
	if game.active_vehicle:
		game.active_vehicle.occupied = false
		game.active_vehicle = null
	if game.active_aircraft:
		game.active_aircraft.occupied = false
		game.active_aircraft = null
	if game.player:
		game.player.in_vehicle = false
		game.player.set_hidden(false)
		game.player.reset_combat()
	game.camera.follow = game.player
	game.camera.set_aircraft_mode(false)
	game.touch.set_driving(false)
	game.touch.firing = false
	game.touch.aiming = false
	if arena:
		# Detach immediately so a restarted scene cannot ray-hit old actors.
		remove_child(arena)
		arena.queue_free()
		arena = null
	actors.clear()
	_last_damage.clear()
	_melee_cooldowns.clear()
	_loot.clear()
	_pickup_remaining = 0.0
	if game.has_method("reset_trigger"): game.reset_trigger()
	if game.hud.has_method("reset_feedback"): game.hud.reset_feedback()
	zone = null
	announcer.reset()
	for entry in _ambient:
		if is_instance_valid(entry.node):
			entry.node.process_mode = entry.process_mode
			entry.node.visible = entry.visible
	_ambient.clear()

func start(selected: int) -> void:
	announcer.team_bank = "policia" if player_team == 0 else "faccao"
	if game.has_method("ensure_player"): game.ensure_player()
	_cleanup()
	_restore_free()
	if game.phase == game.Phase.TITLE and _resume_phase >= 0:
		game.phase = _resume_phase
	game.hud.show_results(false)
	game.hud.show_start(false)
	game.hud.set_wanted(0)
	game.hud.set_crime("")
	game.hud.set_distance(-1.0, "")
	game.touch.visible = DisplayServer.is_touchscreen_available()
	if selected == MatchRules.Mode.FREE:
		rules.mode = selected
		rules.state = MatchRules.State.MENU
		if game.phase == game.Phase.TITLE:
			game.phase = game.Phase.STEAL
		game.player.locked = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if not DisplayServer.is_touchscreen_available() else Input.MOUSE_MODE_VISIBLE
		return
	_save_free()
	for group in ["peds", "vehicles", "aircraft"]:
		for node in get_tree().get_nodes_in_group(group):
			_ambient.append({"node": node, "process_mode": node.process_mode, "visible": node.visible})
			node.process_mode = Node.PROCESS_MODE_DISABLED
			node.visible = false
	arena = load("res://scenes/maps/%s.tscn" % ("favela_royale" if selected == MatchRules.Mode.BATTLE else "protege_o_corre")).instantiate() as MatchArena
	add_child(arena)
	actors[0] = game.player
	var count := rules.config.team_size * 2 if selected == MatchRules.Mode.CORRE else rules.config.battle_participants
	var roster: Array = []
	for id in count:
		var team := (player_team if id < rules.config.team_size else 1 - player_team) if selected == MatchRules.Mode.CORRE else id
		var spawn: Vector3
		if selected == MatchRules.Mode.CORRE:
			spawn = arena.bases[team] + Vector3(0, 0.1, (float(id % rules.config.team_size) - float(rules.config.team_size - 1) * 0.5) * 4.0)
		else:
			var angle := TAU * float(id) / count
			spawn = arena.nearest_clear(Vector3(cos(angle) * 90.0, 0.1, sin(angle) * 90.0))
		var actor: Player
		if id == 0:
			actor = game.player
		else:
			var bot := MatchBot.new()
			bot.participant_id = id
			bot.team = team
			bot.role = id % 4
			bot.manager = self
			if game.hud.get("selected_difficulty") != null: bot.set_difficulty(game.hud.selected_difficulty)
			arena.add_child(bot)
			actor = bot
			actors[id] = actor
		actor.global_position = spawn
		actor.vitality.reset()
		actor.configure_tactical(tactical_config)
		actor.vitality.armor = tactical_config.battle_starting_armor if selected == MatchRules.Mode.BATTLE else 0.0
		actor.stamina = 100.0
		actor.velocity = Vector3.ZERO
		actor.locked = true
		actor.owned_weapons.clear()
		actor.magazines.clear()
		actor.ammo = {1: 0, 2: 0, 3: 0, 4: 0}
		actor.weapon = Arsenal.Id.NONE
		if selected == MatchRules.Mode.CORRE:
			actor.give_weapon(Arsenal.Id.PISTOL, 60)
			var primary := int(game.hud.selected_weapon) if id == 0 and game.hud.get("selected_weapon") != null else Arsenal.Id.RIFLE
			actor.give_weapon(primary, 180)
		roster.append({"id": id, "team": team, "name": "Você" if id == 0 else "Bot %02d" % id, "position": spawn})
	rules.prepare(selected, roster, arena.bases)
	game.phase = game.Phase.FREE
	game.camera.global_position = game.player.global_position + Vector3.UP * 1.55
	game.camera.yaw = -PI * 0.5 if selected == MatchRules.Mode.CORRE and player_team == 0 else PI * 0.5
	game.camera.pitch = -0.12
	if selected == MatchRules.Mode.CORRE:
		for team in 2:
			rules.add_objective("%d:flag" % team, team, "BANDEIRA · " + ("POLÍCIA" if team == 0 else "AURORA"), arena.bases[team])
		arena.sync_objectives(rules.objectives)
	else:
		zone = SafeZoneController.new()
		zone.config = load("res://resources/safe_zone_default.tres") as SafeZoneConfig
		zone.event.connect(bus.publish)
		zone.damage_tick.connect(_zone_damage)
		zone.reset(MatchArena.ORIGIN, arena.valid_zone_center)
		_spawn_loot()
		arena.sync_zone(zone.center, zone.radius)
	if game.get("competitive_only") != true:
		for at in [Vector3(-72, 0.3, 42), Vector3(72, 0.3, -42)]:
			var car := Vehicle.new()
			car.kind = Vehicle.Kind.PARKED
			arena.add_child(car)
			car.setup(Vehicle.Kind.PARKED, MatchArena.ORIGIN + at, 0.0)
	_last_player_announced = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if not DisplayServer.is_touchscreen_available() else Input.MOUSE_MODE_VISIBLE

func return_menu() -> void:
	if not competitive():
		_save_free()
	_cleanup()
	_restore_free()
	_resume_phase = game.phase
	rules.mode = MatchRules.Mode.FREE
	rules.state = MatchRules.State.MENU
	game.phase = game.Phase.TITLE
	game.player.locked = true
	game.hud.show_results(false)
	game.hud.show_start(true)
	game.hud.set_mode_text("")
	game.touch.visible = false
	if game.has_method("release_player"): game.release_player()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func restart() -> void:
	start(rules.mode)

func _on_event(name: String, payload: Dictionary) -> void:
	if name == "SHOT_FIRED":
		for actor: Player in actors.values():
			if actor is MatchBot: actor.hear_sound(payload.position, int(payload.participant))
	elif name == "MATCH_STARTED":
		for actor: Player in actors.values():
			actor.locked = false
	elif name == "RESPAWN":
		var actor: Player = actors[payload.participant]
		actor.vitality.reset()
		actor.configure_tactical(tactical_config)
		actor.global_position = rules.participants[payload.participant].spawn
		actor.velocity = Vector3.ZERO
		actor.visible = true
		actor.locked = false
		actor.collision_layer = 2 if payload.participant == 0 else 16
		actor.collision_mask = 1 | 2 | 4 | 8 | 16
		actor.add_ammo(60)
		_last_damage.erase(payload.participant)
	elif name == "ELIMINATION":
		game.hud.add_elimination("%s → %s" % [payload.killer_name, payload.victim_name])
		if payload.killer == 0: game.hud.set_banner("ELIMINAÇÃO CONFIRMADA")
	elif name == "MATCH_FINISHED":
		for actor: Player in actors.values():
			actor.locked = true
		var win: bool = payload.winner == (player_team if rules.mode == MatchRules.Mode.CORRE else 0)
		var standings := ""
		for member in rules.participants.values():
			standings += "%s · %d eliminações / %d mortes\n" % [member.name, member.kills, member.deaths]
		game.hud.present_results("EMPATE" if payload.winner == -1 else ("VITÓRIA" if win else "DERROTA"), rules.score, rules.mode, standings)
		bus.publish("VICTORY" if win else "DEFEAT")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		game._firing = false

func _process(delta: float) -> void:
	if not competitive():
		return
	if game.active_vehicle:
		game.player.global_position = game.active_vehicle.global_position
		if game.active_vehicle.last_impact > 8.0:
			game.player.take_damage(game.active_vehicle.last_impact * 0.15)
			game.active_vehicle.last_impact = 0.0
		if game.active_vehicle.wrecked:
			game.player.take_damage(1000.0)
	if game.active_aircraft:
		game.player.global_position = game.active_aircraft.global_position
	for id in actors:
		rules.participants[id].position = actors[id].global_position
		if rules.state == MatchRules.State.ACTIVE and rules.participants[id].alive and actors[id].health <= 0.0:
			if rules.eliminate(id, int(_last_damage.get(id, -1))):
				_remove_actor(id)
	rules.tick(delta)
	if rules.state == MatchRules.State.ACTIVE:
		if zone:
			zone.tick(delta)
			_zone_visual_remaining -= delta
			if _zone_visual_remaining <= 0.0:
				_zone_visual_remaining = 0.15
				arena.sync_zone(zone.center, zone.radius)
			if rules.alive_ids().size() == 2 and rules.participants[0].alive and not _last_player_announced:
				_last_player_announced = true
				bus.publish("LAST_PLAYER")
		else:
			for id in actors:
				rules.capture(id)
			arena.sync_objectives(rules.objectives)
		if zone:
			_pickup_remaining -= delta
			if _pickup_remaining <= 0.0:
				_pickup_remaining = 0.15
				if rules.participants[0].alive:
					_collect_loot(0, true, tactical_config.pickup_radius)
	_update_hud()

func _remove_actor(id: int) -> void:
	var actor: Player = actors[id]
	actor.locked = true
	actor.reset_combat()
	actor.collision_layer = 0
	actor.collision_mask = 0
	actor.visible = false
	if id == 0:
		if game.active_vehicle:
			game.active_vehicle.occupied = false
			game.active_vehicle.speed = 0.0
			game.active_vehicle = null
		game.player.in_vehicle = false
		game.camera.follow = game.player
		game.camera.set_vehicle_mode(false)
		game.touch.set_driving(false)
		game._firing = false

func participant_for(actor: Node) -> int:
	for id in actors:
		if actors[id] == actor:
			return id
	return -1

func apply_hit(attacker: int, actor: Node, amount: float, bypass_armor := false) -> bool:
	var id := participant_for(actor)
	if id < 0 or amount <= 0.0 or (actor as Player).locked or not rules.can_damage(attacker, id):
		return false
	_last_damage[id] = attacker
	var target := actor as Player
	var before := target.vitality.armor
	target.take_damage(amount, bypass_armor)
	if id == 0 and amount > 0.0 and game.hud.has_method("show_damage"):
		var direction := Vector2.ZERO
		if actors.has(attacker):
			var to: Vector3 = actors[attacker].global_position - target.global_position
			var local := Basis(Vector3.UP, game.camera.yaw).inverse() * to
			direction = Vector2(local.x, local.z).normalized()
		game.hud.show_damage(direction, bypass_armor)
	if attacker == 0 and game.hud.has_method("confirm_hit"):
		if game.get("competitive_only") == true:
			game.hud.confirm_hit(before > target.vitality.armor, before > 0.0 and target.vitality.armor <= 0.0)
		else:
			game.hud.confirm_hit()
	return true

func melee(id: int) -> bool:
	if not actors.has(id) or rules.state != MatchRules.State.ACTIVE or float(_melee_cooldowns.get(id, 0.0)) > rules.elapsed:
		return false
	var source: Player = actors[id]
	for target_id in actors:
		if target_id == id or not rules.can_damage(id, target_id): continue
		var target: Player = actors[target_id]
		if source.global_position.distance_to(target.global_position) > 1.7: continue
		var from := source.global_position + Vector3.UP * (0.7 if source.crouched else 1.0)
		var to := target.global_position + Vector3.UP * (0.7 if target.crouched else 1.0)
		var query := PhysicsRayQueryParameters3D.create(from, to, 1 | 2 | 16, [source.get_rid()])
		var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
		if hit and hit.collider == target:
			_melee_cooldowns[id] = rules.elapsed + rules.config.melee_interval
			if apply_hit(id, target, rules.config.melee_damage):
				return true
	return false

func _zone_damage(amount: float) -> void:
	for id in actors:
		if rules.participants[id].alive and not zone.contains(actors[id].global_position):
			apply_hit(-1, actors[id], amount, true)

func interact_player() -> bool:
	if not competitive() or rules.state != MatchRules.State.ACTIVE or not rules.participants[0].alive or game.player.in_vehicle:
		return false
	if zone:
		return _collect_loot(0)
	for item: ObjectiveState in rules.objectives.values():
		if rules.interact(0, item.id):
			return true
	if game.player.global_position.distance_to(arena.bases[player_team]) < 5.0 and rules.carried_by(0) == null:
		game.player.ammo[game.player.weapon] = maxi(int(game.player.ammo.get(game.player.weapon, 0)), 120)
		game.player.add_plates(tactical_config.plate_capacity)
		game.hud.set_banner("ARSENAL · MUNIÇÃO E PLACAS REPOSTAS")
		return true
	return false

func _enemy_position(id: int) -> Vector3:
	if id == 0 and game.active_vehicle:
		return game.active_vehicle.global_position + Vector3.UP
	return actors[id].global_position + Vector3.UP * (0.75 if actors[id].crouched else 1.2)

func decide_bot(bot: MatchBot) -> void:
	if rules.state != MatchRules.State.ACTIVE or not rules.participants[bot.participant_id].alive:
		return
	var id := bot.participant_id
	if zone and not zone.contains(bot.global_position):
		bot.bot_state = "ZONE"
		bot.move_to(zone.center)
		return
	var needs_loot := zone != null and (bot.weapon == Arsenal.Id.NONE or (int(bot.magazines.get(bot.weapon, 0)) <= 0 and int(bot.ammo.get(bot.weapon, 0)) <= 0))
	var weapon_loot_available := false
	for supply in _loot:
		if supply.available and supply.kind in [0, 1]: weapon_loot_available = true
	var enemy := -1
	var nearest := bot.difficulty.sight_range
	for other in actors:
		if other == id or not rules.can_damage(id, other):
			continue
		var distance: float = bot.global_position.distance_to(actors[other].global_position)
		if distance >= nearest:
			continue
		if bot.can_perceive(actors[other], _enemy_position(other)):
			nearest = distance
			enemy = other
	if enemy >= 0:
		bot.cancel_plate()
		bot.observe_enemy(enemy, actors[enemy].global_position)
		bot.bot_state = "ATTACK"
		if nearest < 1.7:
			bot.route = PackedVector3Array()
			melee(id)
			return
		if needs_loot and weapon_loot_available:
			bot.bot_state = "LOOT"
			bot.move_to(_nearest_loot(bot.global_position, true))
			_collect_loot(id)
			return
		if nearest > 16.0 or needs_loot:
			bot.move_to(actors[enemy].global_position)
		else:
			bot.route = PackedVector3Array()
		if bot.reacted(): _bot_fire(bot, enemy)
		return
	if needs_loot and weapon_loot_available:
		bot.bot_state = "LOOT"
		bot.move_to(_nearest_loot(bot.global_position, true))
		_collect_loot(id)
		return
	if bot.vitality.armor < tactical_config.armor_maximum and bot.armor_plates > 0:
		bot.request_plate()
	if zone:
		bot.bot_state = "HUNT"
		if bot.memory_until > rules.elapsed:
			bot.move_to(bot.last_seen)
		elif bot.route_index >= bot.route.size() or bot.global_position.distance_to(bot.target_position) < 2.0:
			var angle := randf_range(0, TAU)
			var destination := arena.nearest_clear(zone.center + Vector3(cos(angle), 0, sin(angle)) * randf_range(0.0, zone.radius * 0.65))
			bot.move_to(destination if zone.contains(destination) else zone.center)
		_collect_loot(id)
		return
	var carried := rules.carried_by(id)
	if carried:
		bot.bot_state = "DELIVER"
		bot.move_to(arena.bases[bot.team])
		return
	for item: ObjectiveState in rules.objectives.values():
		if item.owner == bot.team and item.state == ObjectiveState.Status.DROPPED:
			bot.bot_state = "RECOVER"
			bot.move_to(item.position)
			rules.interact(id, item.id)
			return
	if bot.role == MatchBot.Role.ESCORT:
		for member in rules.participants.values():
			if member.team == bot.team and member.id != id and rules.carried_by(member.id):
				bot.bot_state = "ESCORT"
				bot.move_to(member.position + Vector3(0, 0, 3))
				return
	if bot.role == MatchBot.Role.DEFENDER:
		bot.bot_state = "DEFEND"
		bot.move_to(arena.bases[bot.team] + Vector3(-10 if bot.team == 1 else 10, 0, 0))
		return
	var target: ObjectiveState
	var best := INF
	for item: ObjectiveState in rules.objectives.values():
		if item.owner != bot.team and item.state in [ObjectiveState.Status.AT_BASE, ObjectiveState.Status.DROPPED]:
			var distance := bot.global_position.distance_to(item.position)
			if distance < best:
				best = distance
				target = item
	if target:
		bot.bot_state = "STEAL"
		bot.move_to(target.position)
		rules.interact(id, target.id)

func _bot_fire(bot: MatchBot, victim: int) -> void:
	if bot.attack_remaining > 0.0 or bot.weapon == Arsenal.Id.NONE:
		return
	if int(bot.magazines.get(bot.weapon, 0)) == 0:
		bot.request_reload()
		if int(bot.ammo.get(bot.weapon, 0)) == 0 and rules.mode == MatchRules.Mode.CORRE:
			bot.add_ammo(60)
		return
	if not bot.can_fire():
		return
	bot.spend_shot()
	bot.attack_remaining = bot.difficulty.fire_interval if is_equal_approx(rules.config.bot_interval, 0.65) else rules.config.bot_interval
	var from := bot.global_position + Vector3.UP * 1.3
	var to := _enemy_position(victim)
	var accuracy := bot.difficulty.accuracy if is_equal_approx(rules.config.bot_accuracy, 0.7) else rules.config.bot_accuracy
	if randf() > accuracy:
		to += Vector3(randf_range(-1.5, 1.5), randf_range(-0.7, 0.7), 0)
	var query := PhysicsRayQueryParameters3D.create(from, to + (to - from).normalized() * 0.5, 1 | 2 | 4 | 8 | 16, [bot.get_rid()])
	var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		to = hit.position
		if hit.collider is Player:
			var data := Arsenal.data(bot.weapon)
			apply_hit(bot.participant_id, hit.collider, rules.config.bot_damage * bot.difficulty.damage_multiplier * data.damage_at(from.distance_to(to)) / maxf(data.damage, 0.01))
		elif hit.collider is Vehicle:
			hit.collider.apply_damage(rules.config.bot_damage)
	game.shot_effects.emit_shot(from, to, not hit.is_empty())
	bus.publish("SHOT_FIRED", {"participant": bot.participant_id, "position": from})
	bot.rotation.y = atan2(-(to - from).x, -(to - from).z)
	if rules.mode == MatchRules.Mode.CORRE and to.distance_to(arena.bases[player_team]) < 12.0:
		bus.publish("BASE_UNDER_ATTACK")

func _spawn_loot() -> void:
	for i in loot_config.count:
		var angle := TAU * float(i) / maxi(loot_config.count, 1)
		var radius := 45.0 if i % 2 == 0 else 65.0
		var at := arena.nearest_clear(Vector3(cos(angle) * radius, 0.2, sin(angle) * radius))
		var view := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.5, 0.4, 0.5)
		view.mesh = mesh
		var kind: int = loot_config.distribution[i % loot_config.distribution.size()] if not loot_config.distribution.is_empty() else 0
		view.material_override = Palette.mat([Color("efad45"), Color("ddd68a"), Color("64c4dd"), Color("8eecc0")][clampi(kind, 0, 3)])
		arena.add_child(view)
		view.global_position = at + Vector3.UP * 0.2
		var tag := Label3D.new()
		tag.text = ["ARMA", "MUNIÇÃO", "PLACAS", "CURA"][clampi(kind, 0, 3)]
		tag.font_size = 24
		tag.position.y = 0.6
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		view.add_child(tag)
		var weapon: int = loot_config.weapons[i % loot_config.weapons.size()] if not loot_config.weapons.is_empty() else Arsenal.Id.PISTOL
		_loot.append({"position": at, "kind": kind, "weapon": weapon, "available": true, "mesh": view})

func _nearest_loot(at: Vector3, weapon_only := false) -> Vector3:
	var best := INF
	var result := zone.center
	for item in _loot:
		if weapon_only and item.kind not in [0, 1]:
			continue
		if item.available and at.distance_to(item.position) < best:
			best = at.distance_to(item.position)
			result = item.position
	return result

func _collect_loot(id: int, automatic_only := false, radius := -1.0) -> bool:
	if not actors.has(id) or rules.state != MatchRules.State.ACTIVE or not rules.participants[id].alive: return false
	var actor: Player = actors[id]
	for item in _loot:
		if automatic_only and item.kind not in [1, 2]: continue
		if not item.available or actor.global_position.distance_to(item.position) > (radius if radius >= 0.0 else rules.config.interaction_distance):
			continue
		if (item.kind == 2 and actor.armor_plates >= tactical_config.plate_capacity) or (item.kind == 3 and actor.health >= actor.vitality.maximum):
			continue
		var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 0.75, item.position + Vector3.UP * 0.3, 1)
		if not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
		item.available = false
		item.mesh.visible = false
		match item.kind:
			0: actor.give_weapon(item.weapon, loot_config.weapon_rounds)
			1:
				if actor.weapon == Arsenal.Id.NONE: actor.give_weapon(Arsenal.Id.PISTOL, loot_config.ammo_rounds)
				else: actor.add_ammo(loot_config.ammo_rounds)
			2: actor.add_plates(loot_config.plate_count)
			3: actor.heal(loot_config.heal_amount)
		if id == 0:
			game.hud.set_banner(["ARMA EQUIPADA", "MUNIÇÃO COLETADA", "+%d PLACAS · 4 PARA APLICAR" % loot_config.plate_count, "CURA COLETADA"][item.kind])
		return true
	return false

func _update_hud() -> void:
	var mode_name := "FACÇÃO × POLÍCIA · BANDEIRAS" if rules.mode == MatchRules.Mode.CORRE else "FAVELA ROYALE"
	var status := "%s  ·  %02d:%02d" % [mode_name, int(rules.remaining) / 60, int(rules.remaining) % 60]
	if rules.mode == MatchRules.Mode.CORRE:
		status += "  ·  POLÍCIA %d × %d AURORA" % [rules.score[0], rules.score[1]]
	else:
		status += "  ·  VIVOS %d/%d" % [rules.alive_ids().size(), rules.participants.size()]
	game.hud.set_mode_text(status)
	game.hud.set_stats(game.player.health, game.money, game.player.weapon_label())
	if game.hud.has_method("set_tactical"): game.hud.set_tactical(game.player)
	game.hud.set_combat(game.player.weapon != Arsenal.Id.NONE and not game.player.locked and not game.player.in_vehicle, game.player.aiming, game.player.velocity.length())
	if rules.state == MatchRules.State.COUNTDOWN:
		game.hud.set_objective("COMEÇA EM %d" % ceili(rules.countdown))
		return
	if not rules.participants[0].alive:
		game.hud.set_objective("ELIMINADO · sem respawn" if zone else "RESPAWN EM %d" % ceili(rules.participants[0].respawn))
		game.hud.set_prompt("")
		return
	if zone:
		game.hud.set_objective("%s %ds · Zona %d · raio %.0fm" % ["FECHANDO" if zone.closing else "FECHA EM", ceili(zone.remaining), zone.phase + 1, zone.radius])
		var nearby := nearby_loot()
		game.hud.set_prompt(("E · " + nearby if nearby != "" else "E · loot") + "   4 · placas   R · recarregar   V · câmera   Tab · menu")
		game.touch.set_can_interact(true, "LOOT / CAR")
	else:
		var carried := rules.carried_by(0)
		var deposit := "POLÍCIA" if player_team == 0 else "AURORA"
		game.hud.set_objective("BANDEIRA: retorne à base %s · sua bandeira precisa estar em casa" % deposit if carried else flag_status())
		game.hud.set_prompt("E · bandeira / arsenal   G · soltar   4 · placas   C · cobertura   V · câmera   Esc · pausa")
		game.touch.set_can_interact(true, "BANDEIRA")

func flag_status() -> String:
	var result: Array[String] = []
	for team in 2:
		var own: ObjectiveState = rules.objectives.get("%d:flag" % team)
		if own:
			var state_name: String = ["NA BASE", "COM PORTADOR", "CAÍDA", "RETORNANDO", "CAPTURADA"][own.state]
			var alive := 0
			for member in rules.participants.values():
				if member.team == team and member.alive: alive += 1
			result.append("%s: %s (%d vivos)" % ["POLÍCIA" if team == 0 else "AURORA", state_name, alive])
	return " · ".join(result)

func nearby_loot() -> String:
	var best := rules.config.interaction_distance
	var caption := ""
	for item in _loot:
		var distance: float = game.player.global_position.distance_to(item.position)
		if not item.available or distance > best: continue
		var query := PhysicsRayQueryParameters3D.create(game.player.global_position + Vector3.UP * 0.75, item.position + Vector3.UP * 0.3, 1)
		if not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
		best = distance
		caption = [Arsenal.data(item.weapon).label, "coletar munição", "coletar placas", "coletar cura"][item.kind]
	return caption
