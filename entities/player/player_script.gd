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
@export_category("bobbing values")
@export_group("bobbing up")
@export var bobup_time: float
@export var bobup_distance: float
@export_group("bobbing down")
@export var bobdown_time: float
@export var bobdown_distance: float

var mesh_transform: Transform3D:
	get = get_player_mesh_transform
var can_move_camera := true
var attacking: bool

@onready var camera_pivot := $CameraPivot
@onready var statechart := $StateChart
@onready var jump_timer := %JumpTimer
@onready var dash_timer := %DashTimer
@onready var original_y: float = $PlayerMesh.position.y
@onready var player_mesh := $PlayerMesh
@onready var hp := %Health
@onready var bobbing_tween: Tween = null
@onready var wp_holder := $PlayerMesh/Weapon


func _ready() -> void:
	hp.set_current_health(hp.get_max_health())
	initialize_weapon_signals()


func _physics_process(delta: float) -> void:
	move_and_slide()
	handle_bobbing(delta)
	set_player_rotation()
	$UI/HealthUI.update_hearts(hp.current_health)
	manage_weapon_position()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("attack"):
		do_attack()


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


func handle_bobbing(_delta) -> void:
	var spd := Vector2(velocity.x, velocity.z).length_squared()
	if bobbing_tween != null:
		return
	else:
		if spd > 0:
			bobbing_tween = get_tree().create_tween() as Tween
			bobbing_tween.set_trans(Tween.TRANS_SPRING)
			bobbing_tween.set_ease(Tween.EASE_OUT)
			bobbing_tween.tween_property(
				player_mesh,
				"position",
				Vector3(0, bobup_distance, 0),
				bobup_time,
			)
			bobbing_tween.tween_property(
				player_mesh,
				"position",
				Vector3(0, bobdown_distance, 0),
				bobdown_time,
			)
			await bobbing_tween.finished
			bobbing_tween = null


func set_player_rotation() -> void:
	var dir = get_direction()
	if dir.length() > 0:
		player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(-dir.x, -dir.z), 0.4)


func initialize_weapon_signals() -> void:
	var x = wp_holder.get_child(0) as Weapon
	x.started_anim.connect(wp_anim_start)
	x.ended_anim.connect(wp_anim_end)


func manage_weapon_position() -> void:
	wp_holder.global_position = player_mesh.global_position
	if !attacking:
		wp_holder.global_rotation = player_mesh.global_rotation


func do_attack() -> void:
	var x = wp_holder.get_child(0) as Weapon
	x.attack()


func wp_anim_start(anim: String) -> void:
	if anim == "attack":
		attacking = true


func wp_anim_end(anim: String) -> void:
	if anim == "attack":
		attacking = false


func _on_hurtbox_hit(_who: Node3D, damage: int) -> void:
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
