@tool
class_name FunkinCameraController extends Resource

var camera: Node

@export_category("Filters")
@export var filters_array: Array[ShaderMaterial]: set = set_filters

@export_category("Shakes")
@export var shakes: Array[CameraShake]

@export_tool_button("Flash") var f = flash
@export_tool_button("Fade In") var i = fade_in
@export_tool_button("Fade Out") var o = fade_out


var main_viewport: SubViewport #Set in FunkinCameraServer
var viewports_created: Array[SubViewport] #Set in FunkinCameraServer
var is_3d_camera: bool = false

func _process(delta: float) -> void:
	if shakes: FunkinCameraServer._camera_update_shakes(self, delta)

#region Filters
func set_filters(filters: Array[ShaderMaterial]): filters_array = filters; FunkinCameraServer.camera_refresh_shader_materials(self)
func add_filter(f: ShaderMaterial): FunkinCameraServer.camera_add_shader_material(self, f)
func remove_filter(f: ShaderMaterial): FunkinCameraServer.camera_remove_shader_material(self, f)
func clear_filters(): FunkinCameraServer.camera_clear_shader_materials(self)
#endregion

func fade_in(color: Color = Color.BLACK,time: float = 1.0) -> void: ##Fade the camera.
	FunkinCameraServer.camera_fade(camera, color, time, false)

func fade_out(color: Color = Color.BLACK,time: float = 1.0) -> void: ##Fade the camera.
	FunkinCameraServer.camera_fade(camera, color, time, true)

func flash(color: Color = Color.WHITE, time: float = 1.0) -> void: ##Flash bang:
	FunkinCameraServer.camera_flash(camera, color, time)

func shake(intensity: float, time: float = 0.0) -> CameraShake:
	var n = CameraShake.new(intensity,time)
	shakes.append(n)
	return n
