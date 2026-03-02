@tool
@icon("res://icons/Camera2D.svg")
class_name FunkinCamera2D extends Node2D

var controller: FunkinCameraController = FunkinCameraController.new()
var scroll_camera: FunkinScroll2D = FunkinScroll2D.new()
var _shake_pos: Vector2: set = _set_shake_pos


@export_category("Transform2D")
@export var zoom: float = 1.0: set = _set_zoom, get = _get_zoom
@export var default_zoom: float = 1.0
@export var scroll: Vector2: set = set_scroll
@export var size: Vector2: set = set_size
@export var scrollOffset: Vector2: set = set_scroll_offset
@export var angle: float: set = set_angle, get = _get_angle

var bg: CameraBG = CameraBG.new()

@export var auto_resize: bool = true ##If [code]true[/code], the camera will be follow the window size when its resized.
@export var try_to_follow_aspect: bool = false

var _aspect_offset: Vector2:
	set(val): _aspect_offset = val; _update_scroll_position()
##The front index. 
##When the [method add] is called and [param front] is [code]false[/code],
##the node will be added at this index.
@export var _front_index: int


signal resized()
#region Native Methods
func _init() -> void:
	controller.camera = self
	if !Engine.is_editor_hint():
		scroll_camera.child_entered_tree.connect(_on_child_entered)
		scroll_camera.child_exiting_tree.connect(_on_child_exiting)
		scroll_camera.child_order_changed.connect(_on_child_order_changed)
	
func _ready() -> void:
	_update_custom_rect()
	bg.modulate = Color(1.0,1.0,1.0,0.0); 
	bg.name = &'bg'
	add_child(bg,false,INTERNAL_MODE_BACK)
	
	FunkinCameraServer._camera_setup_scroll(controller)
	size = ScreenUtils.screenSize
	get_window().size_changed.connect(_window_size_changed.call_deferred)

func _process(delta: float) -> void: controller._process(delta)

func _enter_tree() -> void: _update_camera_size()



func _update_scroll_position() -> void: scroll_camera.scroll = scroll - scrollOffset + _shake_pos + _aspect_offset

func _update_custom_rect() -> void:
	if !is_node_ready(): return
	var rid = get_canvas_item()
	RenderingServer.canvas_item_set_custom_rect(rid,true,Rect2(Vector2.ZERO,size));
	RenderingServer.canvas_item_set_clip(rid,true)


func _window_size_changed():
	if !auto_resize: return
	if try_to_follow_aspect: _aspect_offset -= (ScreenUtils.screenSize - size) * 0.5
	size = ScreenUtils.screenSize
	_update_camera_size()

func _update_camera_size() -> void: 
	if !is_node_ready(): return
	scroll_camera.pivot_offset = size * 0.5
	_update_custom_rect()
#endregion

#region Properties Methods
func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"bg_color": bg.modulate = value
		_: return false
	return true

func _get(property: StringName) -> Variant:
	match property:
		&"bg_color": return bg.modulate
	return

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"flashSprite",&"_first_index",\
		&"_scroll_position",\
		&"_shake_pos",&"_is_shaking",\
		&"_shader_image",&"_viewports_created",&"_last_viewport_added",\
		&"remove": property.usage = PROPERTY_USAGE_NONE
		&"controller": property.usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_NO_INSTANCE_STATE

func _get_property_list() -> Array[Dictionary]:
	return [
		{"name": "bg_color", "type": TYPE_COLOR, "usage": PROPERTY_USAGE_EDITOR}
	]

func _property_can_revert(property: StringName) -> bool:
	match property:
		&"size",&"zoom",&"shakeTime",&"shakeIntensity": return true
	return false

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&'zoom': return default_zoom
		&"size": return ScreenUtils.screenSize
		&'default_zoom': return 1.0
		&'scrollOffset': return Vector2.ZERO
		&'angle',&"shakeTime",&'shakeIntensity',&'x',&'y': return 0.0
	return null
#endregion

#region Insert/Remove Nodes Methods
func add(node: Node,front: bool = true) -> void: ##Add a node to the camera, if [code]front = false[/code], the node will be added behind of the first node added.
	if !node: return
	if front: _add_object_to_camera(node)
	else: insert(_front_index, node)

func insert(index: int, node: Node) -> void: ##Insert the node at [param index].
	if !node: return;
	_add_object_to_camera(node); 
	move(node,index)

func move(node: Node, index: int) -> void: scroll_camera.move_child(node, index)

func _add_object_to_camera(node: Node) -> void:
	if node.is_inside_tree(): node.reparent(scroll_camera)
	else: scroll_camera.add_child(node)
	node.set_meta(&"is_front_camera",true)
#endregion

#region Setters
func set_scroll(s: Vector2): scroll = s; _update_scroll_position()
func set_scroll_offset(s: Vector2): scrollOffset = s; _update_scroll_position()
func _set_shake_pos(s: Vector2): _shake_pos = s; _update_scroll_position()
func set_angle(s: float): scroll_camera.rotation = deg_to_rad(s);
func set_size(s: Vector2): size = s; _update_camera_size(); resized.emit();
func _set_zoom(s: float): scroll_camera.zoom = s
#endregion

#region Getters
func _get_angle() -> float: return rad_to_deg(scroll_camera.rotation)
func _get_zoom() -> float: return scroll_camera.zoom
#endregion

#region Child Order
enum ChildAction{
	NONE,
	ENTERED_TREE,
	EXITED_TREE,
}
var _child_action: ChildAction = ChildAction.NONE
func _on_child_entered(node: Node) -> void:
	node.set_meta(&"is_front_camera", true)
	_child_action = ChildAction.ENTERED_TREE

func _on_child_order_changed() -> void:
	match _child_action:
		ChildAction.ENTERED_TREE, ChildAction.EXITED_TREE:
			_child_action = ChildAction.NONE
		_:
			var i = scroll_camera.get_child_count()
			while i:
				i -= 1
				_check_child_ordened(scroll_camera.get_child(i))

func _check_child_ordened(node: Node) -> void:
	var _on_front = node.get_meta(&"is_front_camera", true)
	if node.get_index() <= _front_index:
		if _on_front: 
			_front_index += 1
			node.set_meta(&"is_front_camera", false)
	else:
		if not _on_front: 
			_front_index -= 1
			node.set_meta(&"is_front_camera", true)

func _on_child_exiting(node: Node) -> void:
	if _is_node_behind(node): _front_index -= 1
	node.remove_meta(&"is_front_camera")
	_child_action = ChildAction.EXITED_TREE

func _is_node_behind(node: Node) -> bool: return node.get_index() < _front_index
#endregion

func _input(event: InputEvent) -> void:
	if controller.main_viewport: controller.main_viewport.push_input(event)
