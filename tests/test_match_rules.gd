extends SceneTree
var checks := 0
var failures := 0
var events: Array[String] = []
var damage_ticks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func roster(count: int, battle := false) -> Array:
	var result: Array = []
	for id in count:
		result.append({"id": id, "team": id if battle else id % 2, "name": str(id), "position": Vector3(id * 3, 0, 0)})
	return result

func run() -> void:
	var rules := MatchRules.new()
	rules.event.connect(func(name: String, _data: Dictionary) -> void: events.append(name))
	var bases := {0: Vector3(-10, 0, 0), 1: Vector3(10, 0, 0)}
	rules.prepare(MatchRules.Mode.CORRE, roster(8), bases)
	rules.add_objective("package", 1, "Pacote", Vector3(10, 0, 0))
	rules.add_objective("package", 1, "Duplicado", Vector3.ZERO)
	check(rules.participants.size() == 8 and rules.objectives.size() == 1, "4v4 roster and unique objective IDs")
	rules.participants[0].position = Vector3(10, 0, 0)
	check(not rules.interact(0, "package"), "countdown prevents early objective theft")
	rules.tick(2.0)
	check(rules.state == MatchRules.State.COUNTDOWN, "countdown remains active before deadline")
	rules.tick(1.0)
	check(rules.state == MatchRules.State.ACTIVE and events.has("MATCH_STARTED"), "countdown starts match once")
	check(not rules.interact(0, "missing"), "unknown objectives rejected")
	check(rules.interact(0, "package"), "enemy can collect objective in range")
	check(not rules.interact(2, "package") and not rules.interact(0, "package"), "carried objective cannot duplicate")
	check(not rules.capture(0) and rules.score == [0, 0], "capture outside own deposit rejected")
	check(rules.drop(0), "carrier may drop objective")
	check(rules.objectives.package.state == ObjectiveState.Status.DROPPED, "drop stores world position and return timer")
	rules.participants[1].position = Vector3(10, 0, 0)
	check(rules.interact(1, "package"), "owner recovers dropped objective")
	check(rules.objectives.package.state == ObjectiveState.Status.RETURNING, "recovery reserves objective during return")
	rules.tick(0.5)
	check(rules.objectives.package.state == ObjectiveState.Status.AT_BASE and events.has("OBJECTIVE_RETURNED"), "recovery returns to original base")
	rules.interact(0, "package")
	rules.drop(0)
	rules.tick(29.0)
	check(rules.objectives.package.state == ObjectiveState.Status.DROPPED, "drop stays available before 30 seconds")
	rules.tick(1.0)
	check(rules.objectives.package.state == ObjectiveState.Status.AT_BASE, "abandoned objective auto returns at 30 seconds")
	rules.interact(0, "package")
	check(rules.eliminate(0, 1), "enemy elimination accepted")
	check(rules.objectives.package.state == ObjectiveState.Status.DROPPED and not rules.participants[0].alive, "carrier death drops exactly one package")
	check(not rules.eliminate(0, 1), "duplicate death rejected")
	check(events.count("FIRST_BLOOD") == 1, "first blood emitted once")
	rules.tick(4.9)
	check(not rules.participants[0].alive, "no early respawn")
	rules.tick(0.1)
	check(rules.participants[0].alive and rules.participants[0].position == rules.participants[0].spawn, "respawn at five seconds uses own spawn")
	check(not rules.can_damage(1, 0), "spawn protection blocks farming")
	rules.tick(2.0)
	check(rules.can_damage(1, 0) and not rules.can_damage(2, 0), "enemy damage resumes and friendly damage blocked")
	rules.participants[0].position = rules.objectives.package.position
	rules.interact(0, "package")
	rules.participants[0].position = bases[0]
	check(rules.capture(0) and rules.score == [1, 0], "valid capture grants exact point")
	check(not rules.capture(0) and rules.score == [1, 0], "repeated capture cannot score twice")
	rules.tick(2.0)
	check(rules.objectives.package.state == ObjectiveState.Status.AT_BASE, "captured objective recycled for score target above object count")
	rules.config.winning_score = 2
	rules.participants[0].position = rules.objectives.package.position
	rules.interact(0, "package")
	rules.participants[0].position = bases[0]
	rules.capture(0)
	check(rules.state == MatchRules.State.FINISHED and rules.winner == 0, "score target determines winning team")
	check(not rules.can_damage(0, 1) and not rules.interact(1, "package"), "finished match rejects gameplay mutations")
	var snapshot := rules.snapshot()
	snapshot.score[0] = 99
	check(rules.score[0] == 2, "state snapshots do not alias authoritative score")
	rules.prepare(MatchRules.Mode.CORRE, roster(8), bases)
	rules.tick(3.0)
	rules.tick(600.0)
	check(rules.winner == -1 and rules.state == MatchRules.State.FINISHED, "equal score at timeout deterministically draws")
	rules.prepare(MatchRules.Mode.BATTLE, roster(12, true), bases)
	rules.tick(3.0)
	for id in range(1, 12): rules.eliminate(id, 0)
	rules.resolve_survivors()
	check(rules.winner == 0 and rules.alive_ids() == [0], "battle last survivor wins")
	rules.tick(100.0)
	check(not rules.participants[1].alive and rules.participants[1].respawn < 0.0, "battle elimination is permanent")
	rules.prepare(MatchRules.Mode.BATTLE, roster(2, true), bases)
	rules.tick(3.0)
	rules.eliminate(0, 1)
	rules.eliminate(1, 0)
	rules.resolve_survivors()
	check(rules.winner == -1 and rules.alive_ids().is_empty(), "simultaneous deaths yield deterministic draw")
	check(not rules.first_blood == false and rules.objectives.is_empty() and rules.score == [0, 0], "new match clears objective and score residues")
	var zone := SafeZoneController.new()
	zone.config.initial_radius = 84.0
	zone.config.waits = [1.0, 1.0]
	zone.config.closures = [2.0, 2.0]
	zone.config.ratios = [0.7, 0.2]
	zone.damage_tick.connect(func(_amount: float) -> void: damage_ticks += 1)
	zone.reset(Vector3.ZERO)
	check(zone.next_center.distance_to(zone.center) + zone.next_radius <= zone.radius + 0.001, "new safe circle is contained in previous circle")
	zone.tick(1.0)
	check(zone.closing and zone.radius == 84.0, "zone waits then starts closure")
	zone.tick(1.0)
	check(zone.radius < 84.0 and zone.radius > 58.8, "zone interpolates smoothly during closure")
	zone.tick(4.0)
	check(zone.finished and is_equal_approx(zone.radius, 16.8), "all closures end at configured final radius")
	check(damage_ticks == 6, "zone damage emits stable one-second quanta")
	check(zone.contains(zone.center) and not zone.contains(Vector3(1000, 0, 0)), "outside-zone classification uses horizontal distance")
	var announcer := AnnouncerManager.new()
	root.add_child(announcer)
	announcer.set_process(false)
	announcer.on_event("ELIMINATION", {"killer": 0, "victim": 1, "time": 1.0})
	announcer.on_event("ELIMINATION", {"killer": 0, "victim": 2, "time": 5.0})
	check(announcer.queue.size() == 1 and announcer.queue[0].name == "DOUBLE_KILL", "double kill inside five-second window")
	announcer.reset()
	announcer.on_event("ELIMINATION", {"killer": 0, "victim": 1, "time": 1.0})
	announcer.on_event("ELIMINATION", {"killer": 0, "victim": 2, "time": 6.1})
	check(announcer.queue.is_empty(), "kills outside window do not announce double")
	announcer.reset()
	for id in 4:
		announcer.on_event("ELIMINATION", {"killer": 0, "victim": id + 1, "time": float(id)})
	check(announcer.queue.size() == 1 and announcer.queue[0].name == "QUAD_KILL", "higher multikill replaces conflicting queued announcements")
	announcer.request("OBJECTIVE_STOLEN")
	announcer.request("VICTORY")
	check(announcer.take_next().name == "VICTORY", "announcer selects highest priority")
	check(not announcer.request("VICTORY"), "event cooldown rejects duplicate announcement")
	announcer.set_enabled(false)
	check(not announcer.request("FIRST_BLOOD") and announcer.queue.is_empty(), "disable clears queue and prevents speech/subtitles")
	announcer.set_enabled(true)
	var voice := announcer.voice_for("FIRST_BLOOD")
	check(voice != null and voice.get_length() > 0.0, "provided original OGG recording loads with positive duration")
	announcer.request("FIRST_BLOOD")
	announcer._process(0.01)
	check(announcer._speaker.playing and announcer._speaker.stream == voice, "announcer starts real recording through AudioStreamPlayer")
	announcer.set_enabled(false)
	check(not announcer._speaker.playing, "disable stops active audio playback")
	announcer.queue_free()
	await process_frame
	print("MATCH_RULES: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
