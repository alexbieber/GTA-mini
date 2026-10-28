class_name Progression
extends Resource
## Offline profile. Only authority-accepted match events should call observe().
signal changed(profile: Dictionary)
@export var elimination_xp := 25
@export var capture_xp := 80
@export var victory_xp := 120
@export var level_thresholds := PackedInt32Array([0, 200, 500, 1000, 1800, 3000])
@export var level_titles := PackedStringArray(["Recruta", "Firmeza", "Sentinela", "Guardião da rua", "Veterano do bairro", "Lenda do Caos"])
var profile_path := "user://progression.cfg"
var xp := 0
var last_error := OK
var _events: Dictionary = {}
var _won_rounds: Dictionary = {}
var _loaded := false

func valid_config() -> bool:
	if elimination_xp < 0 or capture_xp < 0 or victory_xp < 0: return false
	if level_thresholds.is_empty() or level_thresholds[0] != 0 or level_titles.size() != level_thresholds.size(): return false
	for index in range(1, level_thresholds.size()):
		if level_thresholds[index] <= level_thresholds[index - 1]: return false
	return true

func load_profile(path := "user://progression.cfg") -> Error:
	profile_path = path
	_loaded = false
	if not valid_config():
		last_error = ERR_INVALID_DATA
		return last_error
	var config := ConfigFile.new()
	last_error = config.load(profile_path)
	if last_error == ERR_FILE_NOT_FOUND:
		xp = 0
		_events = {}
		_won_rounds = {}
		_loaded = true
		last_error = OK
		return last_error
	if last_error != OK: return last_error
	var stored_xp: Variant = config.get_value("profile", "xp", -1)
	var stored_events: Variant = config.get_value("profile", "events", null)
	var stored_wins: Variant = config.get_value("profile", "won_rounds", null)
	if config.get_value("profile", "version", 0) != 1 or not stored_xp is int or stored_xp < 0 or not stored_events is Dictionary or not stored_wins is Dictionary:
		last_error = ERR_INVALID_DATA
		return last_error
	for key in stored_events:
		if not key is String or not stored_events[key] is int or stored_events[key] < 0:
			last_error = ERR_INVALID_DATA
			return last_error
	for key in stored_wins:
		if not key is String or stored_wins[key] != true:
			last_error = ERR_INVALID_DATA
			return last_error
	xp = stored_xp
	_events = stored_events.duplicate(true)
	_won_rounds = stored_wins.duplicate(true)
	_loaded = true
	return OK

func save_profile() -> Error:
	var config := ConfigFile.new()
	config.set_value("profile", "version", 1)
	config.set_value("profile", "xp", xp)
	config.set_value("profile", "events", _events)
	config.set_value("profile", "won_rounds", _won_rounds)
	last_error = config.save(profile_path)
	return last_error

func observe(name: String, payload: Dictionary, round_id: String, local_participant: int) -> int:
	if not _loaded or not valid_config() or local_participant < 0 or round_id.is_empty(): return 0
	var event_id: String = str(payload.get("event_id", ""))
	if event_id.is_empty(): return 0
	# Length-prefixed identity prevents concatenation collisions between rounds.
	var key := "%d:%s%d:%s" % [round_id.length(), round_id, event_id.length(), event_id]
	if _events.has(key): return 0
	var reward := 0
	var win := false
	match name:
		"ELIMINATION":
			if int(payload.get("killer", -1)) == local_participant and int(payload.get("victim", -1)) >= 0 and int(payload.get("victim", -1)) != local_participant:
				reward = elimination_xp
		"OBJECTIVE_CAPTURED":
			if int(payload.get("participant", -1)) == local_participant: reward = capture_xp
		"VICTORY":
			win = int(payload.get("participant", -1)) == local_participant
		"MATCH_FINISHED":
			var winner := int(payload.get("winner", -1))
			var mode := int(payload.get("mode", -1))
			win = winner >= 0 and ((mode == 2 and winner == local_participant) or (mode == 1 and payload.has("local_team") and winner == int(payload.local_team)))
	if win:
		if _won_rounds.has(round_id): return 0
		reward = victory_xp
	if reward <= 0: return 0
	var previous_xp := xp
	xp += reward
	_events[key] = reward
	if win: _won_rounds[round_id] = true
	if save_profile() != OK:
		xp = previous_xp
		_events.erase(key)
		if win: _won_rounds.erase(round_id)
		return 0
	changed.emit(info())
	return reward

func info() -> Dictionary:
	var index := 0
	for candidate in level_thresholds.size():
		if xp >= level_thresholds[candidate]: index = candidate
	var maximum := index == level_thresholds.size() - 1
	var target := -1 if maximum else level_thresholds[index + 1]
	var start := level_thresholds[index]
	var progress := 1.0 if maximum else clampf(float(xp - start) / float(target - start), 0.0, 1.0)
	var titles: Array[String] = []
	for unlocked in index + 1: titles.append(level_titles[unlocked])
	return {"xp": xp, "level": index + 1, "title": level_titles[index], "next_level_xp": target, "progress": progress, "unlocked_titles": titles}
