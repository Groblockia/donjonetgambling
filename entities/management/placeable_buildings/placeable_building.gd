class_name ManagementPlaceableBuilding extends Area3D

var mouse_pressed: bool


func mouse_hover(x: bool) -> void:
	if x:
		#$MeshInstance3D.get_active_material(0).next_pass.set_instance_shader_parameter("outline_transparency", 1.0)
		$MeshInstance3D.set_instance_shader_parameter("outline_transparency", 1.0)
	else:
		#$MeshInstance3D.get_active_material(0).next_pass.set_instance_shader_parameter("outline_transparency", 0.0)
		$MeshInstance3D.set_instance_shader_parameter("outline_transparency", 0.0)
