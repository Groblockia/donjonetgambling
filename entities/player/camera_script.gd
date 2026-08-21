extends Node3D

const SENSITIVITY_SCALE: float = 0.00038397243458548043006658879114174

@export_category("accesibility settings")
@export var mouse_sens := 3.5
@export var joystick_sens := 5.0
@export var deadzone := 0.05

@export_category("misc")
@export var center_camera_time := 0.2

var mouse_motion: Vector2
var joystick_motion: Vector2

@onready var camera := %PlayerCamera
@onready var spring_arm := $SpringArm3D
@onready var player: Player = get_parent()


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#SignalBus.mouse_sens_changed.connect(_on_mouse_sens_changed)


func _process(delta: float) -> void:
	mouse_movement()
	joystick_movement(delta)
	#print(spring_arm.rotation.x)
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
	# 1. Extract the target Euler angles from the player's transform.
	var player_euler: Vector3 = player.mesh_transform.basis.get_euler()

	# 2. Convert the isolated axes back into Quaternions
	var target_y: Quaternion = Quaternion.from_euler(Vector3(0, player_euler.y, 0))
	var target_x: Quaternion = Quaternion.from_euler(
		Vector3(player_euler.x + deg_to_rad(-25), 0, 0)
	)

	var t = get_tree().create_tween()
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ease(Tween.EASE_IN_OUT)

	# 3. Tween the "quaternion" property instead of "rotation"
	# CameraPivot rotation (Yaw / Y-axis)
	t.tween_property(self, "quaternion", target_y, center_camera_time)

	# SpringArm rotation (Pitch / X-axis)
	t.parallel().tween_property(spring_arm, "quaternion", target_x, center_camera_time)
	await t.finished
	player.can_move_camera = true
