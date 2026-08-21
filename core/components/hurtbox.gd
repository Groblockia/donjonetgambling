class_name Hurtbox extends Area3D

signal hit(damage: float)

func _ready() -> void:
	area_entered.connect(send_damage)


func send_damage(body: Node3D):
	if body is Hitbox:
		hit.emit(body.damage)
