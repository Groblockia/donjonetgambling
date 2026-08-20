class_name Player
extends CharacterBody3D

@export_category("movement stats")
@export var speed := 6.0
@export var accel := 1.0

@onready var camera_pivot := $CameraPivot
@onready var statechart := $StateChart


func _physics_process(_delta: float) -> void:
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func get_input_direction() -> Vector2:
	return Input.get_vector("left", "right", "forward", "backward")


func get_direction() -> Vector3:
	var input_dir = get_input_direction()
	return transform.basis * Vector3(input_dir.x, 0, input_dir.y).rotated(
		Vector3.UP,
		camera_pivot.rotation.y,
	)


func set_move_velocity(direction: Vector3, _speed: float, _accel: float = accel) -> void:
	velocity.x = lerpf(velocity.x, direction.x * _speed, _accel)
	velocity.z = lerpf(velocity.z, direction.z * _speed, _accel)


func is_moving() -> bool:
	if Input.get_vector("left", "right", "forward", "backward").length() > 0:
		return true
	else:
		return false


#func set_player_rotation() -> void:
#var dir = get_direction()
#if dir.length() > 0:
#player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(-dir.x, -dir.z), 0.4)

#region STATE_MACHINE


func _on_idle_state_physics_processing(_delta: float) -> void:
	set_move_velocity(get_direction(), 0)
	if is_moving():
		statechart.send_event("event_move")


func _on_moving_state_processing(_delta: float) -> void:
	set_move_velocity(get_direction(), speed)
	if !is_moving():
		statechart.send_event("event_idle")


#endregion
