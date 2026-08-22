extends Node3D

const SENSITIVITY_SCALE: float = 0.00038397243458548043006658879114174

@export_category("accesibility settings")
@export var mouse_sens := 3.5
@export var joystick_sens := 5.0
@export var deadzone := 0.05

@export_category("misc")
@export var center_camera_time := 0.4

var mouse_motion: Vector2
var joystick_motion: Vector2
var camera_not_moving: bool:
	get:
		return mouse_motion == Vector2.ZERO #&& joystick_motion == Vector2.ZERO

@onready var camera := %PlayerCamera
@onready var spring_arm := $SpringArm3D
@onready var player: Player = get_parent()


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta: float) -> void:
	mouse_movement()
	joystick_movement(delta)
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-75), deg_to_rad(60))


func _unhandled_input(event: InputEvent) -> void:
	if player.can_move_camera:
		if event is InputEventMouseMotion:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				mouse_motion.x = event.screen_relative.x
				mouse_motion.y = event.screen_relative.y

		if event is InputEventJoypadMotion:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				if event.axis == JOY_AXIS_RIGHT_X:
					if abs(event.axis_value) > deadzone:
						joystick_motion.x = event.axis_value
					else:
						joystick_motion.x = 0
				elif event.axis == JOY_AXIS_RIGHT_Y:
					if abs(event.axis_value) > deadzone:
						joystick_motion.y = event.axis_value
					else:
						joystick_motion.y = 0

		if event.is_action_pressed("reset_camera"):
			player.can_move_camera = false
			reset_camera()


func mouse_movement() -> void:
	rotate_y(-mouse_motion.x * (mouse_sens * SENSITIVITY_SCALE))
	spring_arm.rotate_x(-mouse_motion.y * (mouse_sens * SENSITIVITY_SCALE))
	mouse_motion = Vector2.ZERO


func joystick_movement(delta) -> void:
	rotate_y(-joystick_motion.x * joystick_sens * delta)
	spring_arm.rotate_x(-joystick_motion.y * joystick_sens * delta)


func reset_camera() -> void:
	var player_euler: Vector3 = player.mesh_transform.basis.get_euler()

	var quat_y: Quaternion = Quaternion.from_euler(Vector3(0, player_euler.y, 0))
	var quat_x: Quaternion = Quaternion.from_euler(Vector3(player_euler.x + deg_to_rad(-25), 0, 0))

	var t = get_tree().create_tween()
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ease(Tween.EASE_IN_OUT)

	# CameraPivot rotation (Yaw / Y-axis)
	t.tween_property(self, "quaternion", quat_y, center_camera_time)

	# SpringArm rotation (Pitch / X-axis)
	t.parallel().tween_property(spring_arm, "quaternion", quat_x, center_camera_time)

	await t.finished
	player.can_move_camera = true


## returns angle betzeen camera's resting pos and current pos, in rad
func get_camera_angle_from_player() -> float:
	return wrapf(global_rotation.y - player.player_mesh.global_rotation.y, -PI, PI)
