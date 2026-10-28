class_name CityAudio
extends Node

const RATE := 22050

var _steps: AudioStreamPlayer
var _engine: AudioStreamPlayer
var _radio: AudioStreamPlayer
var _step_cd := 0.0
var _step_side := 0
var _foot_a: AudioStreamWAV
var _foot_b: AudioStreamWAV
var _engine_loop: AudioStreamWAV
var _stinger: AudioStreamWAV


func _ready() -> void:
	_foot_a = make_footstep(0)
	_foot_b = make_footstep(1)
	_engine_loop = make_engine()
	_stinger = make_stinger()
	_steps = _player(_foot_a, -8.0)
	_engine = _player(_engine_loop, -16.0)
	_radio = _player(_stinger, -6.0)


func tick(delta: float, body: Player, vehicle: Vehicle, rank_up: int) -> void:
	if rank_up > 0:
		_radio.play()
	_step_cd = maxf(_step_cd - delta, 0.0)
	_tick_steps(body)
	_tick_engine(vehicle)


func _tick_steps(body: Player) -> void:
	if body == null or body.in_vehicle or body.locked or not body.is_on_floor():
		return
	var planar := Vector2(body.velocity.x, body.velocity.z).length()
	if planar < 0.8 or _step_cd > 0.0:
		return
	_step_side = 1 - _step_side
	_steps.stream = _foot_b if _step_side == 1 else _foot_a
	_steps.pitch_scale = 1.08 if body.sprinting else 0.94
	_steps.play()
	_step_cd = 0.32 if body.sprinting else 0.48


func _tick_engine(vehicle: Vehicle) -> void:
	if vehicle == null or not vehicle.occupied:
		if _engine.playing:
			_engine.stop()
		return
	var cap := maxf(vehicle.max_speed, 1.0)
	var amount := clampf(absf(vehicle.speed) / cap, 0.0, 1.0)
	_engine.pitch_scale = engine_pitch(vehicle.speed, cap)
	_engine.volume_db = lerpf(-18.0, -7.0, amount)
	if not _engine.playing:
		_engine.play()


func _player(stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	player.bus = "Master"
	add_child(player)
	return player


static func engine_pitch(speed: float, cap: float) -> float:
	var amount := clampf(absf(speed) / maxf(cap, 1.0), 0.0, 1.0)
	return lerpf(0.78, 1.95, amount)


static func make_footstep(side: int) -> AudioStreamWAV:
	var count := int(RATE * 0.09)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var tone := 86.0 if side == 0 else 74.0
	for i in count:
		var t := float(i) / float(RATE)
		var env := exp(-t * 36.0)
		var thump := sin(t * TAU * tone) * exp(-t * 55.0)
		var grit := sin(float(i) * (17.0 + float(side) * 3.0)) * sin(float(i) * 0.41)
		samples[i] = clampf((thump * 0.55 + grit * 0.45) * env, -1.0, 1.0)
	return _pcm(samples, false)


static func make_engine() -> AudioStreamWAV:
	var period := 441
	var cycles := 8
	var samples := PackedFloat32Array()
	samples.resize(period * cycles)
	for i in samples.size():
		var phase := float(i % period) / float(period)
		var sample := sin(phase * TAU) * 0.62
		sample += sin(phase * TAU * 2.0) * 0.22
		sample += sin(phase * TAU * 3.0) * 0.08
		sample += sin(phase * TAU * 5.0) * 0.04
		samples[i] = clampf(sample * 1.25, -1.0, 1.0)
	return _pcm(samples, true)


static func make_stinger() -> AudioStreamWAV:
	var count := int(RATE * 0.62)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / float(RATE)
		var sample := 0.0
		if t < 0.07:
			sample += sin(float(i) * 23.0) * sin(float(i) * 0.17) * (1.0 - t / 0.07) * 0.35
		sample += _beep(t, 0.09, 0.2, 880.0) * 0.55
		sample += _beep(t, 0.26, 0.38, 660.0) * 0.5
		if t > 0.44 and t < 0.58:
			var u := (t - 0.44) / 0.14
			sample += sin(float(i) * 19.0) * (1.0 - u) * 0.18
		samples[i] = clampf(sample, -1.0, 1.0)
	return _pcm(samples, false)


static func _beep(t: float, start: float, end_at: float, freq: float) -> float:
	if t < start or t >= end_at:
		return 0.0
	var u := (t - start) / (end_at - start)
	var env := sin(u * PI)
	return sin((t - start) * TAU * freq) * env


static func _pcm(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var s := clampi(int(round(clampf(samples[i], -1.0, 1.0) * 32767.0)), -32768, 32767)
		bytes.encode_s16(i * 2, s)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream


static func peak(stream: AudioStreamWAV) -> float:
	var loudest := 0.0
	var count := stream.data.size() / 2
	for i in count:
		loudest = maxf(loudest, absf(float(stream.data.decode_s16(i * 2)) / 32767.0))
	return loudest
