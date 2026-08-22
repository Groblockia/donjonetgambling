extends Node

var hearts: Array[TextureRect]

const HEART_EMPTY = preload("uid://c8ga10644b7v0")
const HEART_FULL = preload("uid://bt6kibgxql7x3")


func _ready() -> void:
	for i in $HBoxContainer.get_children():
		if i.is_in_group("heart"):
			hearts.append(i)


func update_hearts(health: int) -> void:
	for i in hearts:
		if health > 0:
			i.texture = HEART_FULL
			health -= 1
		else:
			i.texture = HEART_EMPTY
