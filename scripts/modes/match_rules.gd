class_name MatchRules
extends RefCounted
## Offline authority. Pure state and validation, no visual scene dependencies.
signal event(name: String, payload: Dictionary)
enum Mode { FREE, CORRE, BATTLE }
enum State { MENU, COUNTDOWN, ACTIVE, FINISHED }
var config := MatchConfig.new()
var mode := Mode.FREE
var state := State.MENU
var participants: Dictionary = {}
var objectives: Dictionary = {}
var bases := {0: Vector3.ZERO, 1: Vector3.ZERO}
var score := [0, 0]
var elapsed := 0.0
var remaining := 0.0
var countdown := 0.0
var winner := -1
var first_blood := false

func prepare(selected: int, roster: Array, spawn_bases: Dictionary) -> void:
	mode = selected
	state = State.COUNTDOWN
	participants.clear()
	objectives.clear()
	bases = spawn_bases.duplicate()
	score = [0, 0]
	elapsed = 0.0
	remaining = config.duration_seconds
	countdown = config.countdown_seconds
	winner = -1
	first_blood = false
	for item in roster:
		participants[item.id] = {"id": item.id, "team": item.team, "name": item.name,
			"alive": true, "position": item.position, "spawn": item.position,
			"respawn": -1.0, "protected_until": 0.0, "kills": 0, "deaths": 0}
	event.emit("MATCH_PREPARED", {"mode": mode})

func add_objective(id: String, owner: int, label: String, position: Vector3) -> void:
	if objectives.has(id):
		return
	var item := ObjectiveState.new()
	item.id = id
	item.owner = owner
	item.label = label
	item.original = position
	item.reset()
	objectives[id] = item

func tick(delta: float) -> void:
	if state == State.COUNTDOWN:
		countdown = maxf(countdown - delta, 0.0)
		if countdown <= 0.0:
			state = State.ACTIVE
			event.emit("MATCH_STARTED", {"mode": mode})
		return
	if state != State.ACTIVE:
		return
	elapsed += delta
	remaining = maxf(remaining - delta, 0.0)
	if mode == Mode.CORRE:
		for member in participants.values():
			if not member.alive and member.respawn >= 0.0:
				member.respawn = maxf(member.respawn - delta, 0.0)
				if member.respawn == 0.0:
					member.alive = true
					member.respawn = -1.0
					member.position = member.spawn
					member.protected_until = elapsed + config.spawn_protection_seconds
					event.emit("RESPAWN", {"participant": member.id})
		for item: ObjectiveState in objectives.values():
			if item.state == ObjectiveState.Status.CARRIED:
				item.position = participants[item.carrier].position
			elif item.state in [ObjectiveState.Status.DROPPED, ObjectiveState.Status.RETURNING, ObjectiveState.Status.CAPTURED]:
				item.remaining = maxf(item.remaining - delta, 0.0)
				if item.remaining <= 0.0:
					item.reset()
					event.emit("OBJECTIVE_RETURNED", {"objective": item.id})
		if remaining <= 0.0:
			finish(-1 if score[0] == score[1] else (0 if score[0] > score[1] else 1))
	else:
		resolve_survivors()

func carried_by(id: int) -> ObjectiveState:
	for item: ObjectiveState in objectives.values():
		if item.state == ObjectiveState.Status.CARRIED and item.carrier == id:
			return item
	return null

func interact(id: int, objective_id: String) -> bool:
	if state != State.ACTIVE or mode != Mode.CORRE or not participants.has(id) or not objectives.has(objective_id):
		return false
	var member: Dictionary = participants[id]
	var item: ObjectiveState = objectives[objective_id]
	if not member.alive or member.position.distance_to(item.position) > config.interaction_distance:
		return false
	if item.owner == member.team:
		if item.state != ObjectiveState.Status.DROPPED:
			return false
		item.state = ObjectiveState.Status.RETURNING
		item.remaining = 0.5
		return true
	if item.state not in [ObjectiveState.Status.AT_BASE, ObjectiveState.Status.DROPPED] or carried_by(id) != null:
		return false
	item.state = ObjectiveState.Status.CARRIED
	item.carrier = id
	item.position = member.position
	event.emit("OBJECTIVE_STOLEN", {"participant": id, "objective": item.id})
	return true

func drop(id: int) -> bool:
	var item := carried_by(id)
	if item == null:
		return false
	item.position = participants[id].position
	item.state = ObjectiveState.Status.DROPPED
	item.carrier = -1
	item.remaining = config.dropped_return_seconds
	event.emit("OBJECTIVE_DROPPED", {"participant": id, "objective": item.id})
	return true

func capture(id: int) -> bool:
	if state != State.ACTIVE or mode != Mode.CORRE or not participants.has(id) or not participants[id].alive:
		return false
	var member: Dictionary = participants[id]
	var item := carried_by(id)
	if item == null or item.owner == member.team or member.position.distance_to(bases[member.team]) > config.capture_distance:
		return false
	item.state = ObjectiveState.Status.CAPTURED
	item.carrier = -1
	item.remaining = 2.0
	score[member.team] += item.points
	event.emit("OBJECTIVE_CAPTURED", {"participant": id, "team": member.team, "score": score.duplicate()})
	if score[member.team] >= config.winning_score:
		finish(member.team)
	return true

func can_damage(attacker: int, victim: int) -> bool:
	if state != State.ACTIVE or not participants.has(victim) or not participants[victim].alive:
		return false
	if participants[victim].protected_until > elapsed:
		return false
	if attacker < 0:
		return true
	return participants.has(attacker) and participants[attacker].alive and (mode == Mode.BATTLE or participants[attacker].team != participants[victim].team)

func eliminate(victim: int, attacker := -1) -> bool:
	# Damage was validated when applied. A killer may die in the same tick.
	if state != State.ACTIVE or not participants.has(victim) or not participants[victim].alive:
		return false
	if attacker >= 0 and (not participants.has(attacker) or (mode == Mode.CORRE and participants[attacker].team == participants[victim].team)):
		return false
	var member: Dictionary = participants[victim]
	drop(victim)
	member.alive = false
	member.deaths += 1
	member.respawn = config.respawn_seconds if mode == Mode.CORRE else -1.0
	if attacker >= 0 and attacker != victim:
		participants[attacker].kills += 1
	event.emit("ELIMINATION", {"killer": attacker, "victim": victim, "time": elapsed,
		"killer_name": participants[attacker].name if participants.has(attacker) else "Zona",
		"victim_name": member.name})
	if not first_blood and attacker >= 0 and attacker != victim:
		first_blood = true
		event.emit("FIRST_BLOOD", {"participant": attacker})
	return true

func alive_ids() -> Array[int]:
	var alive: Array[int] = []
	for id in participants:
		if participants[id].alive:
			alive.append(id)
	alive.sort()
	return alive

func resolve_survivors() -> void:
	if state != State.ACTIVE or mode != Mode.BATTLE:
		return
	var alive := alive_ids()
	if alive.size() <= 1:
		finish(alive[0] if alive.size() == 1 else -1)

func finish(winning_id: int) -> void:
	if state == State.FINISHED:
		return
	winner = winning_id
	state = State.FINISHED
	event.emit("MATCH_FINISHED", {"winner": winner, "mode": mode})

func snapshot() -> Dictionary:
	var items: Array = []
	for item: ObjectiveState in objectives.values():
		items.append(item.snapshot())
	return {"mode": mode, "state": state, "score": score.duplicate(), "remaining": remaining,
		"elapsed": elapsed, "winner": winner, "participants": participants.duplicate(true), "objectives": items}
