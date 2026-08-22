class_name Health extends Node

@export var max_health: int
var current_health: int


func _ready() -> void:
	current_health = max_health


func set_max_health(val: int) -> void:
	max_health = val


func get_max_health() -> int:
	return max_health


func set_current_health(val: int) -> void:
	current_health = val


func get_current_health() -> int:
	return current_health


func remove_health(amount: int) -> void:
	current_health -= amount
	if current_health < 0:
		current_health = 0


func add_health(amount: int) -> void:
	current_health += amount
	if current_health > max_health:
		current_health = max_health
