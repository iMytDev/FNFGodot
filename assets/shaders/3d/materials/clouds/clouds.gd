@tool
extends MeshInstance3D
@export_range(0.0,3.0,0.05) var velocity: float = 0.025
func _process(delta: float) -> void: mesh.material.uv1_offset.x += delta*velocity
