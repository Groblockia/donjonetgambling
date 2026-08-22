extends Node3D

@export var heal: int

func _on_hurtbox_hit(who: Node3D, _damage: float) -> void:
	print("caca")
	if who is Player:
		print("pipi")
		who.hp.add_health(heal)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		body.hp.add_health(heal)
