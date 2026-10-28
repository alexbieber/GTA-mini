extends SceneTree
## Run: godot --headless --path . --script tests/test_harbor_feel.gd

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)


func run() -> void:
	var speeds := {}
	var accels := {}
	var brakes := {}
	for kind in [Vehicle.Kind.COUPE, Vehicle.Kind.COP, Vehicle.Kind.CIVILIAN, Vehicle.Kind.MILITARY]:
		var spec: Dictionary = Vehicle.profile(kind)
		speeds[spec["max_speed"]] = true
		accels[spec["accel"]] = true
		brakes[spec["brake"]] = true
	check(speeds.size() == 4, "coupe, cop, civilian, and military do not share a top speed")
	check(accels.size() == 4, "each of those kinds has its own acceleration")
	check(brakes.size() == 4, "each of those kinds has its own brake")
	var coupe: Dictionary = Vehicle.profile(Vehicle.Kind.COUPE)
	var cop: Dictionary = Vehicle.profile(Vehicle.Kind.COP)
	var civil: Dictionary = Vehicle.profile(Vehicle.Kind.CIVILIAN)
	var truck: Dictionary = Vehicle.profile(Vehicle.Kind.MILITARY)
	check(coupe["max_speed"] > cop["max_speed"] and cop["max_speed"] > truck["max_speed"], "coupe is fastest and the truck is slower than a patrol car")
	check(coupe["accel"] > civil["accel"] and civil["accel"] > truck["accel"], "the truck accelerates slower than traffic, which is slower than the coupe")
	check(cop["brake"] > coupe["brake"] and coupe["brake"] > truck["brake"], "patrol brakes hardest and the truck takes the longest to stop")
	check(truck["turn"] < civil["turn"] and civil["turn"] < coupe["turn"], "steering gets heavier from coupe to traffic to truck")

	var foot := CityAudio.make_footstep(0)
	var engine := CityAudio.make_engine()
	var stinger := CityAudio.make_stinger()
	check(CityAudio.peak(foot) > 0.2, "footstep is audible")
	check(engine.loop_mode == AudioStreamWAV.LOOP_FORWARD and CityAudio.peak(engine) > 0.2, "engine loop is audible")
	check(CityAudio.engine_pitch(0.0, 100.0) < CityAudio.engine_pitch(40.0, 100.0), "engine pitch rises with speed")
	check(CityAudio.engine_pitch(100.0, 100.0) > CityAudio.engine_pitch(40.0, 100.0), "engine pitch keeps rising toward top speed")
	check(stinger.loop_mode == AudioStreamWAV.LOOP_DISABLED and stinger.data.size() < engine.data.size() * 6, "radio stinger is a short one-shot")
	check(CityAudio.peak(stinger) > 0.2, "radio stinger is audible")

	print("HARBOR_FEEL: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
