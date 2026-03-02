@tool
@icon("res://icons/Camera3D.svg")
class_name FunkinCamera3D extends Node3D
const LockedCamera3D = preload("uid://duup8gtapd1")

var controller: FunkinCameraController = FunkinCameraController.new()
var scroll_camera: LockedCamera3D = LockedCamera3D.new()
var _shake_pos: Vector2: set = _set_shake_pos

@export_category("Transform3D")
@export var zoom: float = 1.0: set = set_zoom
@export var default_zoom: float = 1.0
@export var scroll: Transform3D: set = set_scroll, get = get_scroll
@export var size: Vector2 = ScreenUtils.screenSize: set = set_size

@export_category("Modulate")
@export var modulate: Color = Color.WHITE:
	set(val):
		if val == modulate: return
		modulate = val
		_check_modulate()

var modulate_node: SolidNode2D = SolidNode2D.new()

#region Native Methods
signal resized()
func _init() -> void: 
	controller.camera = self
	modulate_node.material = CanvasItemMaterial.new()
	modulate_node.material.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	set_zoom()

func _ready() -> void: FunkinCameraServer._camera_setup_scroll(controller); _check_modulate()
func _process(delta: float) -> void: controller._process(delta)
func _input(event: InputEvent) -> void: if controller.main_viewport: controller.main_viewport.push_input(event)

#endregion

#region Setters
func set_size(s: Vector2): size = s
func set_scroll(v: Transform3D): scroll_camera.transform = v
func set_zoom(v: float = zoom): scroll_camera.fov = LockedCamera3D.DEFAULT_FOV / v; zoom = v
func _set_shake_pos(s: Vector2): 
	var s_r = s * 0.0025
	_shake_pos = s; scroll_camera.h_offset = s_r.x; scroll_camera.v_offset = s_r.y
#endregion

#region Getters
func get_scroll() -> Transform3D: return scroll_camera.transform
#endregion

func _check_modulate():
	if !is_node_ready() or Engine.is_editor_hint(): return
	modulate_node.modulate = Color(
		modulate.r * modulate.a,
		modulate.b * modulate.a,
		modulate.g * modulate.a,
		1.0
	) 
	if modulate_node.modulate == Color.WHITE: 
		remove_child(modulate_node)
	elif !modulate_node.is_inside_tree():
		scroll_camera.add_child(modulate_node,false,Node.INTERNAL_MODE_FRONT)
	
	modulate_node.size = ScreenUtils.screenSize


#region Property Methods
func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"controller": property.usage = PROPERTY_USAGE_EDITOR

func _property_can_revert(property: StringName) -> bool:
	match property:
		&"size",&"zoom": return true
	return false

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&'zoom': return default_zoom
		&"size": return ScreenUtils.screenSize
		&'default_zoom': return 1.0
		&'scrollOffset': return Vector2.ZERO
		&'angle': return 0.0
	return null
#endregion
