@tool
class_name CharacterCameraPosition3D extends Resource
const rad_180 = deg_to_rad(180)

@export var position = Vector3(-10,12,-20): 
	set(val): position = val; changed.emit()
@export var rotation = Vector3(0,rad_180,0):
	set(val): rotation = val; changed.emit()
