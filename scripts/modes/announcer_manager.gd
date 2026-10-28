class_name AnnouncerManager
extends Node
signal subtitle_changed(text: String)
@export var enabled := true
@export_range(-40, 6) var volume_db := -6.0
@export var multikill_window := 5.0
@export var event_cooldown := 4.0
var queue: Array[Dictionary] = []
var history: Dictionary = {}
var cooldowns: Dictionary = {}
var active_remaining := 0.0
var clock := 0.0
var _speaker: AudioStreamPlayer
var team_bank := "faccao"
var local_participant := 0
const LINES := {
	"FIRST_BLOOD": ["CAIU O PRIMEIRO!"], "DOUBLE_KILL": ["PEGUEI DOIS ALEMÃO!"],
	"TRIPLE_KILL": ["TRÊS NA CONTA!"], "QUAD_KILL": ["QUATRO! TÁ DE SACANAGEM!"],
	"KILL_STREAK_5": ["O HOMEM TÁ IMPARÁVEL!"], "OBJECTIVE_STOLEN": ["LEVARAM O PACOTE!", "SUMIU A ENCOMENDA!"],
	"OBJECTIVE_RETURNED": ["RECUPERARAM A ENCOMENDA!"], "BASE_UNDER_ATTACK": ["TÃO INVADINDO A BASE!"],
	"ZONE_SHRINKING": ["VAI FECHAR O CERCO!"], "FINAL_CIRCLE": ["ACABOU O ESPAÇO PRA CORRER!"],
	"LAST_PLAYER": ["É VOCÊ CONTRA O MUNDO!"], "VICTORY": ["DEU BOM DEMAIS!"], "DEFEAT": ["DEU RUIM, RAPAZ!"],
	"MATCH_STARTED": ["COMEÇOU O CAOS!"], "OBJECTIVE_CAPTURED": ["CHEGOU A ENCOMENDA! PONTO NA CONTA!"], "HEADSHOT": ["NA MIRA! ACERTO NA CABEÇA!"]}
const PRIORITIES := {"VICTORY": 100, "DEFEAT": 100, "FINAL_CIRCLE": 90, "KILL_STREAK_5": 85,
	"QUAD_KILL": 80, "TRIPLE_KILL": 75, "DOUBLE_KILL": 70, "FIRST_BLOOD": 60,
	"LAST_PLAYER": 65, "OBJECTIVE_STOLEN": 50, "OBJECTIVE_RETURNED": 45,
	"BASE_UNDER_ATTACK": 40, "ZONE_SHRINKING": 55, "MATCH_STARTED": 35, "OBJECTIVE_CAPTURED": 55, "HEADSHOT": 25}

func _ready() -> void:
	_speaker = AudioStreamPlayer.new()
	add_child(_speaker)

func reset() -> void:
	queue.clear()
	history.clear()
	cooldowns.clear()
	clock = 0.0
	active_remaining = 0.0
	if _speaker:
		_speaker.stop()
		_speaker.stream = null
	subtitle_changed.emit("")

func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		reset()

func on_event(name: String, payload: Dictionary) -> void:
	if name == "ELIMINATION":
		var victim: int = payload.victim
		if history.has(victim):
			history[victim].streak = 0
			history[victim].times = []
		var killer: int = payload.killer
		if killer < 0 or killer == victim:
			return
		var time: float = payload.time
		var previous: Dictionary = history.get(killer, {"times": [], "streak": 0})
		var recent: Array = []
		for past in previous.times:
			if time - float(past) <= multikill_window:
				recent.append(past)
		recent.append(time)
		previous.times = recent
		previous.streak += 1
		history[killer] = previous
		if killer != local_participant: return
		var announcement := ""
		if previous.streak == 5: announcement = "KILL_STREAK_5"
		elif recent.size() == 4: announcement = "QUAD_KILL"
		elif recent.size() == 3: announcement = "TRIPLE_KILL"
		elif recent.size() == 2: announcement = "DOUBLE_KILL"
		if announcement != "":
			for i in range(queue.size() - 1, -1, -1):
				if queue[i].participant == killer and queue[i].name in ["DOUBLE_KILL", "TRIPLE_KILL", "QUAD_KILL", "KILL_STREAK_5"]:
					queue.remove_at(i)
			request(announcement, killer)
	elif LINES.has(name):
		request(name, int(payload.get("participant", -1)))

func request(name: String, participant := -1) -> bool:
	if not enabled or not LINES.has(name):
		return false
	var key := "%s:%d" % [name, participant]
	if float(cooldowns.get(key, -100.0)) > clock:
		return false
	cooldowns[key] = clock + event_cooldown
	queue.append({"name": name, "participant": participant, "priority": PRIORITIES.get(name, 0), "expires": clock + 8.0})
	if queue.size() > 12:
		queue.pop_front()
	return true

func take_next() -> Dictionary:
	queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.priority > b.priority)
	while not queue.is_empty():
		var next: Dictionary = queue.pop_front()
		if next.expires >= clock:
			return next
	return {}

func voice_for(name: String) -> AudioStream:
	var candidates: Array[String] = []
	var aliases := {"MATCH_STARTED": "match_start", "OBJECTIVE_CAPTURED": "objective_scored"}
	var banks: Array[String] = [team_bank]
	if name in ["FIRST_BLOOD", "MATCH_STARTED", "ZONE_SHRINKING", "FINAL_CIRCLE"]:
		banks.push_front("shared")
	for bank in banks:
		var folder := "res://audio/announcer/%s" % bank
		var event_id: String = str(aliases.get(name, name.to_lower()))
		var flat := folder.path_join(event_id + ".ogg")
		if ResourceLoader.exists(flat): candidates.append(flat)
		var variants := folder.path_join(event_id)
		if DirAccess.dir_exists_absolute(variants):
			for file in DirAccess.get_files_at(variants):
				if file.get_extension() in ["ogg", "wav"]: candidates.append(variants.path_join(file))
		if not candidates.is_empty(): break
	if candidates.is_empty():
		return null
	return load(candidates[randi() % candidates.size()]) as AudioStream

func _process(delta: float) -> void:
	clock += delta
	if not enabled:
		return
	active_remaining = maxf(active_remaining - delta, 0.0)
	if active_remaining > 0.0:
		return
	var next := take_next()
	if next.is_empty():
		subtitle_changed.emit("")
		return
	var variants: Array = LINES[next.name]
	subtitle_changed.emit(variants[randi() % variants.size()])
	active_remaining = 2.5
	# User-provided OGG files coexist with optional per-event variants.
	var stream := voice_for(next.name)
	if _speaker and stream:
		_speaker.stream = stream
		_speaker.volume_db = volume_db
		_speaker.play()
		active_remaining = maxf(stream.get_length(), 0.1)
