extends Camera3D

@export var move_speed := 0.5

## will be changed in settings later
@export var deadzone := 0.05

var mouse_col: ManagementPlaceableBuilding
var currently_moving_building: ManagementPlaceableBuilding
var moving_building: bool


func _process(_delta: float) -> void:
	highlight_building()
	move_building(currently_moving_building)
	if Input.is_action_pressed("mouse_left_click"):
		moving_building = true


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("right"):
		position.x += move_speed
	if Input.is_action_pressed("left"):
		position.x -= move_speed
	if Input.is_action_pressed("backward"):
		position.z += move_speed
	if Input.is_action_pressed("forward"):
		position.z -= move_speed


func move_building(current_building: ManagementPlaceableBuilding) -> void:
	if moving_building:
		if currently_moving_building != null:
			var ray = ray_to_cursor(true)
			current_building.global_position.x = ray.position.x if ray else current_building.global_position.x
			current_building.global_position.z = ray.position.z if ray else current_building.global_position.z
	else:
		currently_moving_building = null


## sends highlight call to building
func highlight_building() -> void:
	var query := ray_to_cursor()
	if query.size() > 1:
		if query.collider is ManagementPlaceableBuilding:
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


## returns a dict containing: collider_id, collider, normal, position, face_index, rid, shape
## if [param only_pos], doesn't interact with areas
func ray_to_cursor(only_pos: bool = false) -> Dictionary:
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = self

	var ray_length := 1000.0
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_end := ray_origin + camera.project_ray_normal(mouse_pos) * ray_length

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true if !only_pos else false
	var result := space_state.intersect_ray(query)
	return result
