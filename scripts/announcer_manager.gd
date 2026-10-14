extends Node
## Registre como Autoload com o nome Announcer.
signal subtitle_changed(message: String)
signal subtitle_cleared

const AUDIO_ROOT := "res://audio/announcer/"
const DEFAULT_PRIORITY := 10
const PRIORITIES := {
    "first_blood": 70, "double_kill": 65, "triple_kill": 68,
    "quad_kill": 72, "kill_streak_5": 60, "victory": 100,
    "defeat": 100, "final_circle": 90, "last_player": 80,
    "zone_shrinking": 45, "base_under_attack": 55,
    "objective_stolen": 60, "objective_returned": 50,
    "objective_scored": 65, "headshot": 25
}
const LABELS := {
    "first_blood": "CAIU O PRIMEIRO!", "double_kill": "PEGUEI DOIS ALEMÃO!",
    "triple_kill": "TRÊS NA CONTA!", "quad_kill": "QUATRO!",
    "kill_streak_5": "O HOMEM TÁ IMPARÁVEL!", "victory": "VITÓRIA!",
    "defeat": "DERROTA!", "final_circle": "CÍRCULO FINAL!",
    "last_player": "ÚLTIMO SOBREVIVENTE!", "zone_shrinking": "A ZONA ESTÁ FECHANDO!",
    "base_under_attack": "BASE SOB ATAQUE!", "objective_stolen": "OBJETIVO ROUBADO!",
    "objective_returned": "OBJETIVO RECUPERADO!", "objective_scored": "PONTO MARCADO!"
}
@export var enabled := true
@export_range(0.0, 1.0, 0.01) var volume := 0.9
@export var min_repeat_seconds := 3.0
var _player: AudioStreamPlayer
var _last_played := {}
var _current_priority := -1
var _current_event := ""
var _subtitle_timer: Timer

func _ready() -> void:
    _player = AudioStreamPlayer.new()
    _player.name = "AnnouncerAudio"
    add_child(_player)
    _player.finished.connect(_on_finished)
    _subtitle_timer = Timer.new()
    _subtitle_timer.one_shot = true
    add_child(_subtitle_timer)
    _subtitle_timer.timeout.connect(func(): subtitle_cleared.emit())

func announce(event_id: String, force := false) -> bool:
    if not enabled:
        return false
    var file_path := AUDIO_ROOT + event_id + ".ogg"
    if not ResourceLoader.exists(file_path):
        push_warning("Locutor: áudio ausente: " + file_path)
        return false
    var now := Time.get_ticks_msec() / 1000.0
    if not force and _last_played.has(event_id) and now - float(_last_played[event_id]) < min_repeat_seconds:
        return false
    var priority := int(PRIORITIES.get(event_id, DEFAULT_PRIORITY))
    if _player.playing and not force and priority < _current_priority:
        return false
    var stream := load(file_path) as AudioStream
    if stream == null:
        return false
    _last_played[event_id] = now
    _current_event = event_id
    _current_priority = priority
    _player.stop()
    _player.stream = stream
    _player.volume_linear = volume
    _player.play()
    subtitle_changed.emit(str(LABELS.get(event_id, event_id.replace("_", " ").to_upper())))
    _subtitle_timer.start(maxf(stream.get_length(), 1.2))
    return true

func _on_finished() -> void:
    _current_priority = -1
    _current_event = ""
    _subtitle_timer.stop()
    subtitle_cleared.emit()

func stop() -> void:
    _player.stop()
    _on_finished()
