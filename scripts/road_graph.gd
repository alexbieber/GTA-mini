class_name RoadGraph
extends RefCounted

var nodes: Array[Vector3] = []
var links: Array = []


static func grid(xs: Array, zs: Array) -> RoadGraph:
	var g := RoadGraph.new()
	var nx := xs.size()
	var nz := zs.size()
	for zi in nz:
		for xi in nx:
			g.nodes.append(Vector3(float(xs[xi]), 0.15, float(zs[zi])))
	for zi in nz:
		for xi in nx:
			var i := zi * nx + xi
			var nbs: Array = []
			if xi > 0:
				nbs.append(i - 1)
			if xi < nx - 1:
				nbs.append(i + 1)
			if zi > 0:
				nbs.append(i - nx)
			if zi < nz - 1:
				nbs.append(i + nx)
			g.links.append(nbs)
	return g


func nearest(pos: Vector3) -> int:
	var best := 0
	var best_d := 9999.0
	for i in nodes.size():
		var d := pos.distance_squared_to(nodes[i])
		if d < best_d:
			best_d = d
			best = i
	return best


func next_toward(from_i: int, dest: Vector3, avoid_i := -1) -> int:
	var options: Array = links[from_i]
	var best: int = options[0]
	var best_score := -9999.0
	for o in options:
		var idx: int = o
		if idx == avoid_i:
			continue
		var score := -nodes[idx].distance_to(dest)
		score += randf() * 0.4
		if score > best_score:
			best_score = score
			best = idx
	return best


func next_away(from_i: int, threat: Vector3) -> int:
	var options: Array = links[from_i]
	var best: int = options[0]
	var best_d := -1.0
	for o in options:
		var d: float = nodes[o].distance_to(threat)
		if d > best_d:
			best_d = d
			best = o
	return best


func light_open(from_i: int, to_i: int, ignore := false) -> bool:
	if ignore:
		return true
	var a := nodes[from_i]
	var b := nodes[to_i]
	var ns := absf(b.x - a.x) < 1.0
	var tick := int(Time.get_ticks_msec() / 7500.0) % 2
	return (tick == 0) == ns
