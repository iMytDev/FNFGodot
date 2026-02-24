class_name FunkinCameraServer extends FunkinInternal
const View = preload("uid://bsuk447ulcs7u")

static var _flash_sprites: Dictionary[int, CameraFlashRect]
static var _fade_sprites: Dictionary[int, CameraFadeRect]

static func createCamera(tag: String, order: int = 5) -> FunkinCamera2D: return _create_camera(tag,order,FunkinCamera2D)
static func createCamera3D(tag: String, order: int = 5) -> FunkinCamera3D: return _create_camera(tag,order,FunkinCamera3D)

static func _create_camera(tag: StringName, order: int, type: Object = FunkinCamera2D) -> Object:
	if tag in modVars: return modVars[tag]
	var cam = type.new()
	cam.name = tag
	modVars[tag] = cam
	game.add_child(cam)
	game.move_child(cam,order)
	return cam

##Make a camera shake.
static func camera_shake(controller: FunkinCameraController, intensity: float = 0.0, time: float = 1.0) -> CameraShake:
	return controller.shake(float(intensity),float(time))

##Returns a [FunkinCamera2D/FunkinCamera3D] created using [method createCamera] or the game's camera named with [param camera]
static func camera_get(camera: Variant) -> Node: 
	return camera if camera is Node else FunkinProperty.get_property(camera_get_name(camera))
static func camera_get_controller(camera: Variant) -> FunkinCameraController: 
	return camera_get(camera).get("controller")
static func camera_get_name(string: StringName) -> StringName:##Detect the camera name using a String.
	match StringName(string.to_lower()):
		&'hud', &'camhud': return &'camHUD'
		&'other', &'camother': return &'camOther'
		&'game',&'camgame': return &'camGame'
		_: return string


static func _camera_setup_scroll(controller: FunkinCameraController):
	var cam  = controller.camera
	var s = _camera_get_scroll_from_node_path(controller)
	if s: cam.scroll_camera = s;
	else: _camera_add_scroll(cam)

static func _camera_add_scroll(cam: Node):
	cam.scroll_camera.name = &"scroll"; 
	cam.add_child(cam.scroll_camera); 
	if Engine.is_editor_hint(): cam.scroll_camera.owner = cam.get_tree().edited_scene_root

static func _camera_get_scroll_from_node_path(controller: FunkinCameraController, path: NodePath = ^"scroll") -> Node:
	var cam = controller.camera
	var scroll = cam.get_node_or_null(path)
	if scroll: return scroll
	
	var view = controller.main_viewport
	if !view: return
	return view.get_node_or_null(path)

static func _camera_update_shakes(controller: FunkinCameraController, delta: float):
	var cam = controller.camera
	var shake = Vector2.ZERO
	var shakes = controller.shakes
	var i = shakes.size()
	while i:
		i -= 1
		var s: CameraShake = shakes[i]
		if !s: continue
		
		s.cur_time += delta
		if s.cur_time >= s.time:
			if !s.looped and s.time:
				if !Engine.is_editor_hint(): shakes.remove_at(i)
				continue
			s.cur_time = 0.0
		
		var intensity = s.get_real_intensity()
		shake.x += randf_range(-intensity,intensity)*1000.0
		shake.y += randf_range(-intensity,intensity)*1000.0
	cam._shake_pos = shake

static func camera_flash(cam: Node, color: Color = Color.WHITE, time: float = 1.0) -> CameraFlashRect:
	if time <= 0.0 or !cam: return
	var id = cam.get_instance_id()
	var f = _flash_sprites.get(id)
	if !f:
		f = CameraFlashRect.new()
		f.name = &"Flash"
		_flash_sprites[id] = f
		f.tree_exiting.connect(_camera_cancel_flash.bind(cam))
		cam.add_child(f)
	f.modulate = color
	f.speed = 1.0 / time
	return f

static func _camera_cancel_flash(cam: Node): _flash_sprites.erase(cam.get_instance_id())

static func camera_fade(cam: Node, color: Color = Color.BLACK, time: float = 1.0, fadeIn: bool = false) -> CameraFadeRect:
	if !cam: return
	var id = cam.get_instance_id()
	var fade: CameraFadeRect = _fade_sprites.get(id)
	if !fade:
		fade = CameraFadeRect.new()
		fade.name = &"Fade"
		fade.tree_exited.connect(_camera_cancel_fade.bind(cam))
		_fade_sprites[id] = fade
		cam.add_child(fade, false, Node.INTERNAL_MODE_FRONT)
	
	fade.modulate = color
	
	if time > 0.0: fade.speed = 1.0 / time
	else: fade.speed = 1.0
	
	
	if fadeIn: fade.modulate.a = 1.0; fade.speed *= -1
	else: fade.modulate.a = 0.0
	return fade

static func _camera_cancel_fade(cam: Node): _fade_sprites.erase(cam.get_instance_id())

#region Camera Filters
static func camera_add_shader_material(controller: FunkinCameraController, filter: Material) -> void:
	var cam = controller.camera
	var main_viewport = _camera_create_viewport(controller)
	var filters: Array[ShaderMaterial] = controller.filters_array
	
	if filters: 
		var prev_sprite = _camera_create_shader_viewport(cam).get_meta(&"sprite")
		prev_sprite.material = filters.back()
	
	filters.append(filter)
	main_viewport.get_meta(&"sprite").material = filter

static func camera_refresh_shader_materials(controller: FunkinCameraController):
	var cam = controller.camera
	var shaders = controller.filters_array
	var length = shaders.size()
	if !length: camera_clear_shader_materials(controller); return
	
	length -= 1
	_camera_create_viewport(cam)
	while controller.viewports_created.size() < length: 
		_camera_create_shader_viewport(cam)
	while controller.viewports_created.size() > length: 
		controller.viewports_created.pop_back().queue_free()
	
	
	var i: int = 0
	while i < length: 
		controller.viewports_created[i].get_meta(&"sprite").material = shaders[i]
		i += 1
	
	_camera_update_viewports_texture(cam)
	controller.main_viewport.get_meta(&"sprite").material = shaders.back()

static func _camera_update_main_viewport_texture(controller: FunkinCameraController) -> void:
	var view = controller.main_viewport
	if !view: return
	var sprite = view.get_meta(&"sprite")
	
	var views_created = controller.viewports_created
	if views_created: sprite.texture = views_created.back().get_texture()
	else: sprite.texture = view.get_texture()

static func _camera_update_viewports_texture(controller: FunkinCameraController) -> void:
	var main_viewport: SubViewport = controller.main_viewport; if !main_viewport: return
	var cur_viewport: SubViewport = main_viewport
	
	var views_created = controller.viewports_created
	var i: int = 0
	while i < views_created.size():
		var v = views_created[i]; 
		i += 1
		v.get_meta(&"sprite").texture = cur_viewport.get_texture()
		cur_viewport = v
	
	main_viewport.get_meta(&"sprite").texture = cur_viewport.get_texture()

static func camera_remove_shader_material(controller: FunkinCameraController, filter: ShaderMaterial) -> void:
	var filters = controller.filters_array
	var index = filters.find(filter); if index == -1: return
	filters.remove_at(index)
	
	var views_created = controller.viewports_created
	if index < filters.size(): views_created.pop_at(index-1).queue_free()
	
	_camera_update_viewports_texture(controller)
	_camera_update_main_viewport_texture(controller)


static func camera_clear_shader_materials(controller: FunkinCameraController):
	controller.filters_array.clear()
	var cam = controller.camera; if !cam: return
	
	var views_created = controller.viewports_created
	while views_created: views_created.pop_back().queue_free()
	
	_remove_camera_viewport_safe(controller)

static func _camera_create_viewport(controller: FunkinCameraController) -> SubViewport:
	var view = controller.main_viewport
	if controller.main_viewport: return controller.main_viewport
	
	var cam = controller.camera
	view = cam.get_node_or_null(^"Viewport")
	if !view: 
		view = View.new(cam)
		view.name = &"Viewport"
		cam.add_child(view)
		
		cam.scroll_camera.reparent(view)
		if Engine.is_editor_hint(): view.owner = cam.get_tree().edited_scene_root
		view.tree_exiting.connect(cam.scroll_camera.reparent.bind(cam))
	
	controller.main_viewport = view
	var view_sprite = _create_viewport_sprite(view)
	cam.add_child(view_sprite)
	
	_camera_update_main_viewport_texture(controller)
	return view



static func _camera_create_shader_viewport(controller: FunkinCameraController):
	var cam = controller.camera
	var view = View.new(cam)
	cam.add_child(view)
	
	var sprite = _create_viewport_sprite(view)
	view.add_child(sprite)
	
	controller.viewports_created.append(view)
	_camera_update_main_viewport_texture(controller)
	return cam

static func _create_viewport_sprite(view: Viewport) -> Sprite2D:
	var view_sprite = Sprite2D.new()
	view_sprite.centered = false
	view.set_meta(&"sprite",view_sprite)
	return view_sprite

static func _remove_camera_viewport_safe(controller: FunkinCameraController) -> bool:
	if !controller.main_viewport or controller.is_3d_camera or controller.filters_array: return false
	_remove_camera_viewport(controller)
	return true

static func _remove_camera_viewport(controller: FunkinCameraController):
	if !controller.main_viewport: return
	controller.camera.scroll_camera.reparent(controller.camera)
	_queue_free_camera_viewport(controller.main_viewport)
	controller.main_viewport = null

static func _queue_free_camera_viewport(view: SubViewport):view.get_meta(&"sprite").queue_free(); view.queue_free()

#endregion
