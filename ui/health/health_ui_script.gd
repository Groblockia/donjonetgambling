extends Node

@export var curr_hp: Health
var hearts: Array[TextureRect]

const HEART_EMPTY = preload("uid://c8ga10644b7v0")
const HEART_FULL = preload("uid://bt6kibgxql7x3")


func _ready() -> void:
	for i in %HeartContainer.get_children():
		if i.is_in_group("heart"):
			hearts.append(i)

func _process(_delta: float) -> void:
	update_hearts()

func update_hearts() -> void:
	var tmp := curr_hp.get_current_health()
	for i in hearts:
		if tmp > 0:
			i.texture = HEART_FULL
			tmp -= 1
		else:
			i.texture = HEART_EMPTY
