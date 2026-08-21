class_name Player
extends CharacterBody3D

@export_category("movement stats")
@export var speed := 6.0
@export var run_speed := 12.0
@export var accel := 1.0
@export var gravity := 1.0
@export var jump_power := 20.0
@export var jump_time: float:
	set = setter_jump_time
@export_category("jsp frr")
@export var frequency := 10.0
@export var amplitude := PI * 0.05

var t_bob: float

@onready var camera_pivot := $CameraPivot
@onready var statechart := $StateChart
@onready var jump_timer := %JumpTimer
@onready var original_y: float = $Sprite3D.position.y


func _physics_process(delta: float) -> void:
	move_and_slide()
	handle_bobbing(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func setter_jump_time(value: float) -> void:
	if not is_node_ready():
		await ready
	jump_timer.wait_time = value
	jump_time = value


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


func handle_bobbing(delta) -> void:
	var caca := Vector2(velocity.x, velocity.z).length_squared()

	if caca > 0:
		t_bob += delta * frequency
		$Sprite3D.position.y = original_y + sin(t_bob) * amplitude
	else:
		$Sprite3D.position.y = lerp($Sprite3D.position.y, original_y, 0.2)
		t_bob = 0


#func set_player_rotation() -> void:
#var dir = get_direction()
#if dir.length() > 0:
#player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(-dir.x, -dir.z), 0.4)
#region GROUNDED
func _on_grounded_state_physics_processing(_delta: float) -> void:
	if !is_on_floor():
		statechart.send_event("event_fall")

	if Input.is_action_just_pressed("jump"):
		statechart.send_event("event_jump")


func _on_idle_state_physics_processing(_delta: float) -> void:
	set_move_velocity(get_direction(), 0)
	if is_moving():
		statechart.send_event("event_move")


func _on_moving_state_processing(_delta: float) -> void:
	set_move_velocity(get_direction(), speed)
	if !is_moving():
		statechart.send_event("event_idle")
	if Input.is_action_pressed("run"):
		statechart.send_event("event_run")


func _on_running_state_physics_processing(_delta: float) -> void:
	set_move_velocity(get_direction(), run_speed)
	if !is_moving():
		statechart.send_event("event_idle")
	if Input.is_action_just_released("run"):
		statechart.send_event("event_idle")
#endregion

#region AIRBORNE
func _on_fall_state_physics_processing(_delta: float) -> void:
	set_move_velocity(get_direction(), speed, accel)
	velocity.y -= gravity
	if is_on_floor():
		statechart.send_event("event_idle")


func _on_jumping_state_entered() -> void:
	jump_timer.start()
	velocity.y = jump_power


func _on_jumping_state_physics_processing(_delta: float) -> void:
	set_move_velocity(get_direction(), speed, accel)
	if jump_timer.is_stopped():
		velocity.y = jump_power / 2
		statechart.send_event("event_fall")


func _on_jumping_state_unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("jump"):
		jump_timer.stop()
#endregion

func _on_hurtbox_hit(damage: float) -> void:
	print_debug("received ", damage, " damage")
