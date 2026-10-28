class_name CombatReticle
extends Control
var gap := 8.0
var hit_remaining := 0.0
var hit_color := Color("f0a030")

func _process(delta: float) -> void:
	hit_remaining = maxf(hit_remaining - delta, 0.0)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	for axis in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		draw_line(center + axis * gap, center + axis * (gap + 5.0), Color.WHITE, 1.5)
	if hit_remaining > 0.0:
		for axis in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			draw_line(center + axis * 4.0, center + axis * 9.0, hit_color, 2.0)
