@tool
class_name SparrowSprite3D extends Node3D
@export var mesh: SparrowMeshInstance3D = SparrowMeshInstance3D.new()
@export_storage var region_rect: Rect2:
	set(val): mesh.region_rect = val;
	get(): return mesh.region_rect

var frameData: Rect2:
	set(val): frameData = val; _update_frame_data()

var rotated: bool:
	set(val): mesh.rotated = val
	get(): return mesh.rotated

@export var flip_h: bool:
	set(val): mesh.flip_h = val; flip_h = val; _update_frame_data()
@export var flip_v: bool:
	set(val): mesh.flip_v = val; flip_v = val; _update_frame_data()

@export var texture: Texture2D:
	set(val): texture = val; mesh.texture = val;
	get(): return mesh.texture

func _init() -> void: add_child(mesh, false, Node.INTERNAL_MODE_FRONT) 

func _update_frame_data():
	var frameD = frameData
	if flip_h: frameD.position.x *= -1.0
	if flip_v: frameD.position.y *= -1.0
	mesh.frameData = frameD

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"mesh": property.usage = PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		&"texture": property.usage = PROPERTY_USAGE_EDITOR
