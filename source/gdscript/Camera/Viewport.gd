extends SubViewport
var camera_to_follow: Node:
	set(val):
		if camera_to_follow: camera_to_follow.resized.disconnect(_update_size)
		camera_to_follow = val
		if val: val.resized.connect(_update_size)
		
		var is_node_3d = val is Node3D
		transparent_bg = !is_node_3d
		own_world_3d = !is_node_3d
	
func _init(camera: Node = null):
	camera_to_follow = camera
	debug_draw = Viewport.DEBUG_DRAW_DISABLED
	size = ScreenUtils.screenSize

func _update_size() -> void:
	if camera_to_follow: size = camera_to_follow.size
