class_name WorldPickup
extends Area3D

enum Kind { HEALTH, CASH, PACKAGE }

var kind: Kind = Kind.HEALTH
var amount := 25
var taken := false


func setup(p_kind: Kind, pos: Vector3, p_amount := 25) -> void:
	kind = p_kind
	amount = p_amount
	position = pos


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.1
	col.shape = sph
	col.position.y = 0.6
	add_child(col)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.45, 0.45, 0.45)
	mesh.mesh = box
	mesh.position.y = 0.7
	var colr := Color("3dcc6a")
	var glow := Color("5dff88")
	match kind:
		Kind.CASH:
			colr = Color("d4b84a")
			glow = Color("f0d060")
		Kind.PACKAGE:
			colr = Palette.amber()
			glow = Palette.amber()
	mesh.material_override = Palette.mat(colr, 0.2, 0.35, glow, 2.4)
	add_child(mesh)
	body_entered.connect(_on_body)


func _process(delta: float) -> void:
	rotate_y(delta * 1.6)


func _on_body(body: Node) -> void:
	if taken or not body.is_in_group("player"):
		return
	taken = true
	var game := get_tree().current_scene
	if game and game.has_method("collect_pickup"):
		game.collect_pickup(kind, amount)
	queue_free()
