extends Node3D

const SENSITIVITY_SCALE: float = 0.00038397243458548043006658879114174

@export var mouse_sens := 3.5
@export var joystick_sens := 5.0
@export var deadzone := 0.05

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


func mouse_movement() -> void:
	rotate_y(-mouse_motion.x * (mouse_sens*SENSITIVITY_SCALE))
	spring_arm.rotate_x(-mouse_motion.y * (mouse_sens*SENSITIVITY_SCALE))
	mouse_motion = Vector2.ZERO


func joystick_movement(delta) -> void:
	rotate_y(-joystick_motion.x * joystick_sens * delta)
	spring_arm.rotate_x(-joystick_motion.y * joystick_sens * delta)
