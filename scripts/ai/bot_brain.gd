class_name BotBrain
extends RefCounted
## FSM supplements objective planning without taking authority over damage/flags.
enum State { WAIT, PATROL, INVESTIGATE, PURSUE, COMBAT, RELOAD, COVER, RETREAT, OBJECTIVE, LOOT, ZONE }
var state := State.WAIT
var heard_position := Vector3.ZERO
var heard_until := -1.0
var threat_id := -1
var threat_position := Vector3.ZERO
var reaction_until := -1.0
var cover_until := -1.0
var cover_position := Vector3.ZERO
var next_cover_search := 0.0
var previous_health := 100.0

func sync_objective_state(label: String) -> void:
	match label:
		"ZONE": state = State.ZONE
		"LOOT": state = State.LOOT
		"ATTACK": state = State.COMBAT
		"DELIVER", "RECOVER", "ESCORT", "DEFEND", "STEAL": state = State.OBJECTIVE
		"HUNT": state = State.PURSUE if threat_id >= 0 else State.PATROL

func now(bot: MatchBot) -> float:
	return bot.manager.rules.elapsed if bot.manager else 0.0

func observe(bot: MatchBot, id: int, position: Vector3) -> void:
	if threat_id != id or bot.memory_until <= now(bot):
		reaction_until = now(bot) + bot.difficulty.reaction_seconds
	threat_id = id
	threat_position = position
	bot.last_seen = position
	bot.memory_until = now(bot) + bot.difficulty.memory_seconds

func hear(bot: MatchBot, position: Vector3, source: int, loudness: float) -> bool:
	if bot.manager == null or source == bot.participant_id or bot.locked or bot.health <= 0.0: return false
	var rules: MatchRules = bot.manager.rules
	if source >= 0 and rules.participants.has(source) and rules.mode == MatchRules.Mode.CORRE and rules.participants[source].team == bot.team: return false
	var distance := bot.global_position.distance_to(position)
	if distance > minf(bot.difficulty.hearing_range, loudness): return false
	# Occluded shots remain audible at half hearing distance, never grant sight.
	var query := PhysicsRayQueryParameters3D.create(bot.global_position + Vector3.UP, position + Vector3.UP, 1)
	if not bot.get_world_3d().direct_space_state.intersect_ray(query).is_empty() and distance > minf(bot.difficulty.hearing_range, loudness) * 0.5: return false
	heard_position = position
	heard_until = now(bot) + bot.difficulty.memory_seconds
	return true

func plan(bot: MatchBot) -> bool:
	var manager: Node = bot.manager
	if manager == null or manager.rules.state != MatchRules.State.ACTIVE: return false
	if manager.zone and not manager.zone.contains(bot.global_position):
		state = State.ZONE
		return false
	var time := now(bot)
	var visible := false
	for id in manager.actors:
		if manager.rules.can_damage(bot.participant_id, id) and bot.can_perceive(manager.actors[id], manager._enemy_position(id)):
			visible = true
			observe(bot, id, manager.actors[id].global_position)
			break
	var hurt := bot.health < previous_health - 0.01
	previous_health = bot.health
	if bot.health <= bot.vitality.maximum * bot.difficulty.retreat_health_ratio and bot.memory_until > time:
		if time >= next_cover_search:
			next_cover_search = time + 2.0
			cover_position = find_cover(bot, threat_position)
		state = State.RETREAT
		bot.bot_state = "RETREAT"
		bot.move_to(cover_position)
		if not visible and bot.armor_plates > 0: bot.request_plate()
		return true
	if bot.weapon != Arsenal.Id.NONE and int(bot.magazines.get(bot.weapon, 0)) == 0 and int(bot.ammo.get(bot.weapon, 0)) > 0:
		bot.request_reload()
		state = State.RELOAD
		bot.bot_state = "RELOAD"
		if visible:
			if time >= next_cover_search:
				next_cover_search = time + 2.0
				cover_position = find_cover(bot, threat_position)
			bot.move_to(cover_position)
		return true
	if hurt and visible and time >= next_cover_search and manager.rules.carried_by(bot.participant_id) == null:
		next_cover_search = time + 4.0
		cover_position = find_cover(bot, threat_position)
		cover_until = time + 1.4
	if cover_until > time and manager.rules.carried_by(bot.participant_id) == null:
		state = State.COVER
		bot.bot_state = "COVER"
		bot.move_to(cover_position)
		return true
	if visible:
		state = State.COMBAT
		return false
	if manager.rules.carried_by(bot.participant_id) != null:
		state = State.OBJECTIVE
		return false
	if heard_until > time:
		state = State.INVESTIGATE
		bot.bot_state = "INVESTIGATE"
		bot.move_to(manager.arena.nearest_clear(heard_position))
		if bot.global_position.distance_to(heard_position) < 2.5: heard_until = -1.0
		return true
	state = State.PURSUE if bot.memory_until > time else State.PATROL
	return false

func find_cover(bot: MatchBot, threat: Vector3) -> Vector3:
	var arena: MatchArena = bot.manager.arena
	var best := INF
	var found := bot.global_position
	for obstacle in arena.obstacles:
		var center := obstacle.get_center()
		var away := (center - Vector2(threat.x, threat.z)).normalized()
		var edge := center + away * (obstacle.size.length() * 0.5 + 2.0)
		var candidate := arena.nearest_clear(Vector3(edge.x, 0, edge.y))
		var distance := bot.global_position.distance_to(candidate)
		if distance > bot.difficulty.cover_search_radius or distance >= best: continue
		var query := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 1.3, threat + Vector3.UP * 1.3, 1)
		if not bot.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			best = distance
			found = candidate
	if best == INF:
		var retreat := (bot.global_position - threat).normalized()
		found = arena.nearest_clear(bot.global_position + retreat * 8.0)
	return found
