class_name ManagementPlaceableBuilding extends Area3D

## typically height of building/2
@export var height_offset: float

var mouse_pressed: bool


func mouse_hover(x: bool) -> void:
	if x:
		$MeshInstance3D.set_instance_shader_parameter("outline_transparency", 1.0)
	else:
		$MeshInstance3D.set_instance_shader_parameter("outline_transparency", 0.0)
