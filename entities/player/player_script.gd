class_name Player
extends CharacterBody3D

@export_category("movement stats")
@export var speed := 6.0
@export var run_speed := 12.0
@export var accel := 1.0
@export var gravity := 1.0
@export var jump_power := 20.0
@export var jump_time := 0.2
@export var dash_power := 20.0
@export var dash_time := 0.1

@export_category("sprite appearance")
@export var frequency := 10.0
@export var amplitude := PI * 0.05

## Used for the bobbing of the sprite
var t_bob: float
var mesh_transform: Transform3D:
	get = get_player_mesh_transform
var can_move_camera := true

@onready var camera_pivot := $CameraPivot
@onready var statechart := $StateChart
@onready var jump_timer := %JumpTimer
@onready var dash_timer := %DashTimer
@onready var original_y: float = $Sprite3D.position.y
@onready var player_mesh := $Sprite3D

var hp = Health.new(3)


#func _process(_delta: float) -> void:
#mesh_facing_direction = player_mesh.rotation
func _physics_process(delta: float) -> void:
	move_and_slide()
	handle_bobbing(delta)
	set_player_rotation()
	$UI/HealthUI.update_hearts(hp.current_health)
	print(hp.current_health)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func setter_dash_time(value: float) -> void:
	if not is_node_ready():
		await ready
	dash_timer.wait_time = value
	dash_time = value


func setter_jump_time(value: float) -> void:
	if not is_node_ready():
		await ready
	jump_timer.wait_time = value
	jump_time = value


func get_player_mesh_transform() -> Transform3D:
	return player_mesh.global_transform


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


func set_player_rotation() -> void:
	var dir = get_direction()
	if dir.length() > 0:
		player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(-dir.x, -dir.z), 0.4)


func _on_hurtbox_hit(damage: int) -> void:
	print_debug("received ", damage, " damage")
	hp.remove_health(damage)

#region GROUNDED
func _on_grounded_state_physics_processing(_delta: float) -> void:
	if !is_on_floor():
		statechart.send_event("event_fall")

	if Input.is_action_just_pressed("jump"):
		statechart.send_event("event_jump")

	if Input.is_action_just_pressed("dash"):
		statechart.send_event("event_dash")


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


func _on_dash_state_entered() -> void:
	dash_timer.start(dash_time)
	set_move_velocity(get_direction(), dash_power)


func _on_dash_state_physics_processing(_delta: float) -> void:
	if dash_timer.is_stopped():
		statechart.send_event("event_idle")

#endregion

#region AIRBORNE
func _on_fall_state_physics_processing(_delta: float) -> void:
	set_move_velocity(get_direction(), speed, accel / 2)
	velocity.y -= gravity
	if is_on_floor():
		statechart.send_event("event_idle")


func _on_jumping_state_entered() -> void:
	jump_timer.start(jump_time)
	velocity.y = jump_power


func _on_jumping_state_physics_processing(_delta: float) -> void:
	set_move_velocity(get_direction(), speed, accel / 2)
	if jump_timer.is_stopped():
		velocity.y = jump_power / 2
		statechart.send_event("event_fall")


func _on_jumping_state_unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("jump"):
		jump_timer.stop()
#endregion
