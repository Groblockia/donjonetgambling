extends Node3D


@export var move_speed := 0.5
@export var ground_y_level := 0.0
@export var lerp_speed := 10.0
## will be changed in settings later
@export var deadzone := 0.05

var grid_size := 1.0
var mouse_col: ManagementPlaceableBuilding
var dragged_building: ManagementPlaceableBuilding = null

@onready var drag_plane := Plane(Vector3.UP, ground_y_level)
@onready var camera = $Camera3D


func _process(delta: float) -> void:
	highlight_building()

	if dragged_building != null:
		update_dragged_building_position(delta)


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("right"):
		camera.position.x += move_speed
	if Input.is_action_pressed("left"):
		camera.position.x -= move_speed
	if Input.is_action_pressed("backward"):
		camera.position.z += move_speed
	if Input.is_action_pressed("forward"):
		camera.position.z -= move_speed


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("mouse_left_click"):
		if mouse_col != null:
			dragged_building = mouse_col
			# dragged_building.start_dragging()
	if Input.is_action_just_released("mouse_left_click"):
		if dragged_building != null:
			# dragged_building.place()
			dragged_building.global_position = get_snapped_mouse_position()
			dragged_building = null


## calculates where the mouse hits the ground and snaps it to the grid
func get_snapped_mouse_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_normal = camera.project_ray_normal(mouse_pos)

	var intersection = drag_plane.intersects_ray(ray_origin, ray_normal)
	intersection.y += dragged_building.height_offset
	if intersection != null:
		# Apply grid snapping
		if grid_size > 0.0:
			intersection.x = round(intersection.x / grid_size) * grid_size
			intersection.z = round(intersection.z / grid_size) * grid_size
		return intersection

	return dragged_building.global_position if dragged_building else Vector3.ZERO


## smoothly follows the raw mouse cursor position on the ground plane
func update_dragged_building_position(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_normal = camera.project_ray_normal(mouse_pos)

	var intersection = drag_plane.intersects_ray(ray_origin, ray_normal)
	intersection.y += dragged_building.height_offset
	if intersection != null:
		# Lerp toward the raw (unsnapped) intersection for smooth movement
		dragged_building.global_position = dragged_building.global_position.lerp(
			intersection,
			lerp_speed * delta,
		)


## sends highlight call to building
func highlight_building() -> void:
	var query := ray_to_cursor()
	if !query.is_empty():
		if query.collider is ManagementPlaceableBuilding:
			@warning_ignore("standalone_ternary")
			mouse_col.mouse_hover(false) if mouse_col is ManagementPlaceableBuilding else null
			mouse_col = query.collider
			mouse_col.mouse_hover(true)
		else:
			if mouse_col != null:
				mouse_col.mouse_hover(false)
			mouse_col = null
	else:
		if mouse_col != null:
			mouse_col.mouse_hover(false)
		mouse_col = null


## returns a dict containing: collider_id, collider, normal, position, face_index, rid, shape.
## If [param only_pos], doesn't interact with areas
func ray_to_cursor(only_pos: bool = false) -> Dictionary:
	var mouse_pos = get_viewport().get_mouse_position()

	var ray_length := 1000.0
	var ray_origin = camera.project_ray_origin(mouse_pos) as Vector3
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * ray_length as Vector3

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true if !only_pos else false
	var result := space_state.intersect_ray(query)
	return result
