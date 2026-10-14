extends Control
## Testador independente. Execute esta cena com F6 no Godot.
var _status: Label
var _subtitle: Label
var _announcer: Node

func _ready() -> void:
    var wrap := VBoxContainer.new()
    wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    wrap.add_theme_constant_override("separation", 10)
    add_child(wrap)
    var heading := Label.new()
    heading.text = "OPERAÇÃO CAOS | TESTE DO LOCUTOR"
    wrap.add_child(heading)
    _status = Label.new()
    _status.text = "Clique para ouvir sua gravação."
    wrap.add_child(_status)
    _subtitle = Label.new()
    wrap.add_child(_subtitle)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    wrap.add_child(scroll)
    var grid := GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    scroll.add_child(grid)
    for key in AnnouncerTest.get_events():
        var btn := Button.new()
        btn.text = key.replace("_", " ").to_upper()
        btn.custom_minimum_size = Vector2(180, 42)
        btn.pressed.connect(_test.bind(key))
        grid.add_child(btn)
    var announcer := get_node_or_null("/root/Announcer")
    if announcer == null:
        announcer = preload("res://scripts/announcer_manager.gd").new()
        add_child(announcer)
    _announcer = announcer
    if announcer != null:
        announcer.subtitle_changed.connect(func(s: String): _subtitle.text = s)
        announcer.subtitle_cleared.connect(func(): _subtitle.text = "")
    else:
        _status.text = "Configure o Autoload Announcer em Project Settings."

func _test(key: String) -> void:
    var announcer := _announcer
    if announcer == null:
        return
    var ok: bool = announcer.announce(key, true)
    _status.text = ("REPRODUZINDO: " if ok else "ERRO: ") + key

class AnnouncerTest:
    static func get_events() -> Array[String]:
        return ["base_under_attack", "defeat", "double_kill", "final_circle", "first_blood", "headshot", "kill_streak_5", "last_player", "low_ammo", "match_start", "objective_returned", "objective_scored", "objective_stolen", "player_eliminated", "quad_kill", "revenge", "team_wipe", "triple_kill", "victory", "zone_shrinking"]
