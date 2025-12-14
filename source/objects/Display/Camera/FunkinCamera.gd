@tool
@icon("res://icons/Camera2D.svg")
class_name FunkinCamera extends Node2D

#region Properties
@export_category("Transform")
@export var zoom: float = 1.0: set = set_zoom
@export var size: Vector2: set = set_size
@export var pivot_offset: Vector2: set = set_pivot_offset
var _real_pivot_offset: Vector2: set = _set_real_pivot_offset

@export var scroll: Vector2: set = set_scroll
var scroll_transform: Transform2D
var scrollOffset: Vector2: set = set_scroll_offset
var _scroll_position: Vector2: set = _set_scroll_position
var _scroll_camera: Node2D = Node2D.new()
@export_category("Shake")
@export var shakeTime: float
@export var shakeIntensity: float: set = set_shake_intensity
var _shake_pos: Vector2: set = _set_shake_pos
var _is_shaking: bool

var defaultZoom: float = 1.0 #Used in PlayState

@export var angle: float: set = set_angle, get = get_angle
var _angle_rad: float:
	set(val):
		_angle_rad = val;
		_update_pivot()
		_update_transform_scale_zoom()
		_update_canvas_transform()

var bg: SolidSprite = SolidSprite.new()
var _first_index: int

var flashSprite: SolidSprite = SolidSprite.new()

var filtersArray: Array[Material]
var viewport: SubViewport
var _viewports_created: Array[SubViewport]
var _last_viewport_added: SubViewport
var _shader_image: Sprite2D
#endregion

func _update_camera_size(): pivot_offset = size*0.5; if viewport: viewport.size = size

#region Shaders Methods
func setFilters(shaders: Array) -> void: ##Set Shaders in the Camera
	removeFilters()
	if !shaders: return
	
	shaders = _convertFiltersToMaterial(shaders)
	create_viewport()
	create_shader_image()
	
	var index: int = 0
	var size = shaders.size()
	while index < size: addFilter(shaders[index]); index += 1

func addFilter(shader: ShaderMaterial) -> void:
	if shader in filtersArray: return
	create_viewport()
	
	if filtersArray: _addViewportShader(filtersArray.back())
	filtersArray.append(shader)
	_shader_image.material = shader

func addFilters(shaders: Array) -> void: for i in _convertFiltersToMaterial(shaders): addFilter(i) ##Add shaders to the existing ones.

func _addViewportShader(filter: ShaderMaterial) -> Sprite2D:
	if !_last_viewport_added: return
	create_viewport()
	
	var shader_view = _get_new_viewport()
	add_child(shader_view)
	
	if filter.shader.resource_name: shader_view.name = filter.shader.resource_name
	
	var tex = Sprite2D.new()
	tex.name = &'Sprite2D'
	tex.centered = false
	tex.texture = _last_viewport_added.get_texture()
	tex.material = filter
	
	shader_view.add_child(tex)
	_viewports_created.append(shader_view)
	
	_shader_image.texture = shader_view.get_texture()
	_last_viewport_added = shader_view
	return tex

func removeFilter(shader: ShaderMaterial) -> void: ##Remove shaders.
	var filter_id = filtersArray.find(shader)
	if filter_id == -1: return
	
	if filtersArray.size() == 1: removeFilters(); return
	
	filtersArray.remove_at(filter_id)
	var prev_image: Sprite2D
	var shader_viewport = _viewports_created[filter_id]
	var view_image = shader_viewport.get_node('Sprite2D')
	
	if filter_id == filtersArray.size():  prev_image = _shader_image
	else:  prev_image = _viewports_created[filter_id+1].get_node('Sprite2D')
	prev_image.texture = view_image.texture
	_viewports_created.remove_at(filter_id)
	shader_viewport.queue_free()


func removeFilters(): ##Remove every shader created in this camera.
	if !filtersArray: return
	filtersArray.clear()
	if _shader_image: _shader_image.queue_free(); _shader_image = null
	
	if can_remove_viewport(): remove_viewport()
	
	while _viewports_created: _viewports_created.pop_back().queue_free()

func safe_remove_viewport() -> void: if can_remove_viewport(): remove_viewport()

func create_viewport() -> void:
	if viewport: return
	viewport = _get_new_viewport()
	viewport.own_world_3d = true
	
	add_child(viewport)
	_update_transform()
	queue_redraw()
	
	_last_viewport_added = viewport
	
	#scroll_camera.transform = Transform2D(Vector2.RIGHT,Vector2.DOWN,Vector2.ZERO)
	_scroll_camera.reparent(viewport,false)
	queue_redraw()
	create_shader_image()
	
func create_shader_image():
	if _shader_image: return
	
	_shader_image = Sprite2D.new()
	_shader_image.name = &'ViewportTexture'
	_shader_image.centered = false
	_shader_image.texture = viewport.get_texture()
	
	add_child(_shader_image)

func remove_viewport() -> void:
	if !viewport: return
	#scroll_camera.reparent(self,false)
	#move_child(scroll_camera,0)
	queue_redraw()
	viewport.queue_free()
	viewport = null
	queue_redraw()
	_update_transform()

func can_remove_viewport() -> bool: return !filtersArray and not (viewport and viewport.world_3d)
#endregion

#region Effects Methods

#region Shake
##Shake the Camera
func shake(intensity: float, time: float) -> void: shakeIntensity = intensity; shakeTime = time

func _update_shake_time(delta: float):
	if !shakeTime: return
	shakeTime -= delta
	if shakeTime <= 0.0: shakeIntensity = 0; shakeTime = 0; _shake_pos = Vector2.ZERO

func _updateShake(delta: float):
	_update_shake_time(delta)
	_shake_pos.x = randf_range(-shakeIntensity,shakeIntensity)*1000.0
	_shake_pos.y = randf_range(-shakeIntensity,shakeIntensity)*1000.0

#endregion
func fade(color: Variant = Color.BLACK,time: float = 1.0, _force: bool = true, _fadeIn: bool = true) -> void: ##Fade the camera.
	var tag = 'fade'+name
	if !_force and FunkinGD.isTweenRunning(tag): return
	
	flashSprite.modulate = FunkinGD._get_color(color)
	var target = 0.0 if _fadeIn else 1.0
	if !time: FunkinGD.cancelTween(tag); flashSprite.modulate.a = target
	else: 
		FunkinGD.startTweenNoCheck(
			tag,
			flashSprite,{^"modulate:a": target},
			time
		)

func flash(color: Color = Color.WHITE, time: float = 1.0, force: bool = false) -> void: ##Flash bang
	if time <= 0.0: return
	var tag = 'flash'+name
	if !force and FunkinGD.isTweenRunning(tag): return
	flashSprite.modulate = color
	FunkinGD.doTweenAlpha(tag,flashSprite,0.0,time).bind_node = self
#endregion


#region Insert/Remove Nodes Methods
func add(node: Node,front: bool = true) -> void: ##Add a node to the camera, if [code]front = false[/code], the node will be added behind of the first node added.
	if !node: return
	_insert_object_to_camera(node)
	if !front: 
		_scroll_camera.move_child(node,_first_index); 
		_first_index += 1

@warning_ignore("native_method_override")
func move_child(node: Node, order: int): move_to_order(node, order)

func move_to_order(node: Node, index: int):
	if !node: return
	var old_index = node.get_index()
	if old_index == index: return
	index = mini(index,get_child_count())
	if old_index >= _first_index and index < _first_index: _first_index += 1 #If the node was ahead of _first_index and moved before or to _first_index, add to _first_index
	elif old_index < _first_index and index > _first_index: _first_index -= 1 #If the node was before or at _first_index and moved past it, subadd to _first_index
	_scroll_camera.move_child(node, index)

func insert(index: int = 0,node: Object = null) -> void: ##Insert the node at [param index].
	if !node: return
	_insert_object_to_camera(node)
	_scroll_camera.move_to_order(node,index)

func _insert_object_to_camera(node: Node):
	if node.is_inside_tree(): node.reparent(_scroll_camera)
	else: _scroll_camera.add_child(node)
	node.set(&"camera",self)
#endregion

#region Transform
func _update_transform() -> void: _update_zoom(false); _update_pivot()

func _update_pivot() -> void:
	var _real_pivot = pivot_offset - _scroll_position
	var _pivot = _real_pivot
	if zoom != 1.0: _pivot *= zoom
	if _angle_rad: _pivot = _pivot.rotated(_angle_rad)
	_real_pivot_offset = (_pivot - _real_pivot)
	_update_origin()


func _update_zoom(update_pivo: bool = true) -> void:
	_update_transform_scale_zoom()
	if update_pivo: _update_pivot()
	else: _update_canvas_transform()


func _update_origin():
	scroll_transform.origin = _scroll_position - _real_pivot_offset + _shake_pos; _update_canvas_transform()

func _update_transform_scale_zoom():
	var cos_r = cos(_angle_rad) * zoom
	var sin_r = sin(_angle_rad) * zoom
	scroll_transform.x.x = cos_r
	scroll_transform.x.y = sin_r
	scroll_transform.y.x = -sin_r
	scroll_transform.y.y = cos_r

func _update_canvas_transform():
	if viewport: viewport.canvas_transform = scroll_transform
	else: queue_redraw()

#endregion

#region Setters
func set_scroll(val: Vector2) -> void: _scroll_position -= val - scroll; scroll = val;
func set_scroll_offset(val: Vector2) -> void: _scroll_position += val - scrollOffset; scrollOffset = val;
func set_pivot_offset(val: Vector2) -> void: pivot_offset = val; _update_pivot()
func set_size(val: Vector2) -> void: size = val; _update_camera_size()
func set_zoom(val: float) -> void: zoom = val; _update_zoom()
func set_angle(val: float) -> void: _angle_rad = deg_to_rad(val)
func set_angle_radius(val: float) -> void: _angle_rad = val;
func set_shake_intensity(val: float) -> void: shakeIntensity = val; _is_shaking = val; if !_is_shaking: _shake_pos = Vector2.ZERO

func _set_scroll_position(val: Vector2) -> void: _scroll_position = val; _update_pivot();
func _set_real_pivot_offset(val: Vector2) -> void: scroll_transform.origin -= val - _real_pivot_offset; _real_pivot_offset = val;
func _set_shake_pos(val: Vector2) -> void: scroll_transform.origin += val - _shake_pos; _shake_pos = val;
func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"width": size.x = value; return true
		&"height": size.y = value; return true
	return false
#endregion

#region Getters
func get_angle(): return rad_to_deg(_angle_rad)
func _get(property: StringName) -> Variant:
	match property:
		&"width": return size.x
		&"height": return size.y
	return
func _property_get_revert(property: StringName) -> Variant:
	match property:
		&'zoom': return defaultZoom
		&'defaultZoom': return 1.0
		&'scrollOffset': return Vector2.ZERO
		&'angle',&'shakeIntensity',&'x',&'y': return 0.0
	return null
#endregion

#region Native Methods
func _process(delta: float) -> void: if _is_shaking: _updateShake(delta)

@warning_ignore("native_method_override")
func add_child(node: Node, force_readable_name: bool = false, internal: InternalMode = INTERNAL_MODE_DISABLED): 
	_scroll_camera.add_child(node,force_readable_name,internal) 

@warning_ignore("native_method_override")
func get_child_count(include_internal: bool = false) -> int: return _scroll_camera.get_child_count(include_internal)

func _init() -> void:
	bg.modulate = Color.TRANSPARENT
	bg.name = &'bg'
	size = ScreenUtils.screenSize
	
	flashSprite.name = &'flashSprite'
	flashSprite.modulate.a = 0.0
	flashSprite.top_level = true
	#scroll_camera.child_exiting_tree.connect(func(node):
	child_exiting_tree.connect(func(node):
		if node.get_index() < _first_index: _first_index -= 1

	)
	add_child(bg,false,INTERNAL_MODE_BACK)
	add_child(flashSprite,false,INTERNAL_MODE_FRONT)
	add_child(_scroll_camera)

func _draw() -> void:
	var rid = get_canvas_item()
	
	var _real_position = scroll_transform.origin / zoom
	var _real_size = size * zoom
	flashSprite.position = _real_position
	flashSprite.size = _real_size
	
	bg.position = _real_position
	bg.size = _real_size
	if viewport: 
		RenderingServer.canvas_item_set_clip(rid,false);
		RenderingServer.canvas_item_set_custom_rect(rid,false);
		return
	RenderingServer.canvas_item_set_transform(_scroll_camera.get_canvas_item(),scroll_transform)
	RenderingServer.canvas_item_set_custom_rect(rid,true,Rect2(Vector2.ZERO,size));
	RenderingServer.canvas_item_set_clip(rid,true)

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"flashSprite",&"_first_index",\
		&"_scroll_position",\
		&"_shake_pos",&"_is_shaking",\
		&"_shader_image",&"_viewports_created",&"_last_viewport_added",\
		&"remove": property.usage = PROPERTY_USAGE_NONE
#endregion
static func _convertFiltersToMaterial(shaders: Array) -> Array[Material]:
	var array: Array[Material] = []
	for i in shaders:
		var shader: Material = (Paths.loadShader(i) if i is String else i)
		if !shader or shader in array: continue
		array.append(shader)
	return array

static func _get_new_viewport() -> SubViewport:
	var view = SubViewport.new()
	view.transparent_bg = true
	view.disable_3d = true
	view.gui_snap_controls_to_pixels = false
	view.size = ScreenUtils.screenSize
	view.own_world_3d = true
	return view
