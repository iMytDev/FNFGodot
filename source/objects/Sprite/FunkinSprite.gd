@tool
class_name FunkinSprite extends PivotNode2D
const Anim = preload("uid://bv8xd8nuxerrp")
const Graphic = preload("uid://c4kmei8jjkf3n")

#region Camera Vars
var camera: FunkinCamera
#endregion

#region Offset
@export_category("Offset")
@export var offset: Vector2: set = set_offset

##If [code]true[/code], the animation offset will follow the sprite flips.[br][br]
##[b]Example[/b]: if the sprite has flipped horizontally, the [param offset.x] will be inverted horizontally(x)
@export var offset_follow_flip: bool
@export var offset_follow_scale: bool ##If [code]true[/code], the animation offset will be multiplied by the sprite scale when set.
@export var offset_follow_rotation: bool ##If [code]true[/code], the animation offset will follow the rotation.

var _graphic_scale: Vector2: 
	set(val): 
		if _graphic_scale == val: return
		_graphic_scale = val; _update_graphic_offset()

var _graphic_offset: Vector2: 
	set(val): 
		if _graphic_offset == val: return
		position -= val - _graphic_offset; _graphic_offset = val;
#endregion

#region Scroll Factor
@export var scrollFactor: Vector2 = Vector2.ONE: set = set_scroll_factor
var _scroll_offset: Vector2: 
	set(val):
		if _scroll_offset == val: return
		position += val - _scroll_offset; _scroll_offset = val;

var _real_scroll_factor: Vector2
var _needs_factor_update: bool
#endregion

var parent: Node

#region Velocity Vars
@export_category("Velocity")
@export var acceleration: Vector2 = Vector2.ZERO: set = set_aceleration ##This will accelerate the velocity from the value setted.
@export var velocity: Vector2 = Vector2.ZERO: set = set_velocity ##Will add velocity from the position, making the sprite move.
var _accelerating: bool
@export var maxVelocity: Vector2 = Vector2(999999,99999) ##The limit of the velocity, set [Vector2](-1,-1) to unlimited.
#endregion

var _real_offset: Vector2 = Vector2.ZERO:
	set(val):
		val = Vector2(val.x if is_finite(val.x) else 0.0,val.y if is_finite(val.y) else 0.0)
		if val == _real_offset: return
		position -= val - _real_offset; _real_offset = val

var _real_pivot_offset: Vector2: 
	set(val):
		if _real_pivot_offset == val: return
		position -= val - _real_pivot_offset; _real_pivot_offset = val; 

#region Images/Animation Properties
##The Node that will be animated. [br]
##Can be a [Sprite2D] with [member Sprite2D.region_enabled] enabled
## or a [NinePatchRect]
@export var image: CanvasItem = Graphic.new()

##If [code]true[/code], 
##the region_rect of the [param image] will be resized automatically 
##for his texture size every time it's changes.
var _auto_resize_image: bool = true

@export_category("Image")
@export var antialiasing: bool:
	set(anti):
		antialiasing = anti
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if anti else CanvasItem.TEXTURE_FILTER_NEAREST

@export var width: float: ##Texture width, only be changed when the sprite it's not being animated. 
	set(val): image.region_rect.size.x = val
	get(): return image.region_rect.size.x

@export var height: float: ##Texture height, only be changed when the sprite it's not being animated.
	set(val): image.region_rect.size.y = val
	get(): return image.region_rect.size.y

var imageSize: Vector2 ##The texture size of the [member image]

var imageFile: String:  ##The Path from the current image
	get(): return Paths.getPath(imagePath)

var imagePath: String: ##The [b]absolute[/b] Path from the current image
	get(): return image.texture.resource_name if image.texture else &''

@export var animation: Anim ##The animation class. See how to use in [Anim].

#endregion


#region Native Methods
func _init(is_animated: bool = false,texture: Variant = null):
	if is_animated: _create_animation()
	_on_image_changed()
	set_texture(texture)
	add_child(image)


func _process(delta: float) -> void:
	if _needs_factor_update: _update_scroll_factor()
	if _accelerating: _add_velocity(delta)
	if animation: animation.curAnim.process_frame(delta)


func _check_transform() -> void:
	if _last_rotation == rotation and _last_scale == scale: return
	_last_rotation = rotation
	_last_scale = scale
	_update_pivot()
	_update_real_offset()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED: parent = get_parent(); _check_scroll_factor()
		NOTIFICATION_UNPARENTED: parent = null; _needs_factor_update = false
	super._notification(what)
#endregion

#region Animation Methods
func _create_animation() -> void: 
	if animation: return
	_auto_resize_image = false
	animation = Anim.new()
	_connect_animation()

func _kill_animation() -> void:
	animation.stop()
	_auto_resize_image = true
	image.region_rect.size = imageSize
	animation = null

func _update_animation_image() -> void:
	if !animation: return
	animation.image = image
	animation.curAnim.node_to_animate = image

func _connect_animation() -> void:
	animation.image_animation_enabled.connect(func(enabled): _auto_resize_image = !enabled)
	animation.image_parent = self
	_update_animation_image()
	image.region_rect = Rect2(0,0,0,0)

#endregion

#region Velocity Methods
func _check_velocity() -> void: _accelerating = acceleration != Vector2.ZERO or velocity != Vector2.ZERO
func _add_velocity(delta: float) -> void: velocity += acceleration * delta; _position += velocity.clamp(-maxVelocity,maxVelocity) * delta
#endregion

#region Setters
func set_position_xy(_x: float, _y: float) -> void: _position = Vector2(_x,_y);
func set_offset(val: Vector2) -> void: 
	if val == offset: return; 
	offset = val; _update_real_offset(); 
func set_velocity(vel: Vector2) -> void: velocity = vel; _check_velocity() 
func set_aceleration(acc: Vector2) -> void: acceleration = acc; _check_velocity()
func set_scroll_factor(factor: Vector2) -> void: 
	scrollFactor = factor; _real_scroll_factor = Vector2.ONE - factor; _check_scroll_factor()
func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"material": image.material = value; return true
		&"texture": image.texture = value; return true
		&"x": _position.x = value; return true
		&"y": _position.y = value; return true
		&"flipX": image.flip_h = value; return true
		&"flipY": image.flip_v = value; return true
	return super._set(property,value)

func set_pivot_offset(value: Vector2) -> void: 
	if value == pivot_offset: return
	pivot_offset = value; _update_pivot()

#endregion

#region Getters
func _get(property: StringName) -> Variant:
	match property:
		&"material": return image.material;
		&"texture": return image.texture;
		&"x": return _position.x;
		&"y": return _position.y;
		&"flipX": return image.flip_h;
		&"flipY": return image.flip_v;
	return super._get(property)

func _get_real_position() -> Vector2:
	return super._get_real_position() - _real_offset + _scroll_offset - _graphic_offset

func getMidpoint() -> Vector2:
	return _position + _scroll_offset + pivot_offset ##Get the [u]center[/u] position of the sprite in the scene.
#endregion

#region Image Setters
func set_texture(tex: Variant):
	if !tex: image.texture = null; return;
	image.texture = tex if tex is Texture2D else Paths.texture(tex)

func setGraphicScale(_scale: Vector2) -> void: scale = _scale; _graphic_scale = Vector2.ONE-_scale

#endregion

#region Updaters

#region Scroll Factor
func _check_scroll_factor() -> void: _needs_factor_update = scrollFactor != Vector2.ONE

func _update_scroll_factor() -> void:
	var pos: Vector2 = camera.scroll if camera else parent.get(&'position')
	if !pos: _scroll_offset = Vector2.ZERO; return
	_scroll_offset = pos * _real_scroll_factor
#endregion

#region Updaters
func _update_graphic_offset() -> void: _graphic_offset = image.pivot_offset*_graphic_scale

func _update_real_offset() -> void:
	var off = offset
	if offset_follow_scale: off *= scale
	if offset_follow_flip: off *= image.scale
	if offset_follow_rotation: off = off.rotated(rotation)
	_real_offset = off

#endregion

#region Change Signals
func _on_texture_changed() -> void:
	if !image.texture: 
		imageSize = Vector2.ZERO;
		pivot_offset = imageSize; 
		image.pivot_offset = imageSize;
		return
	
	imageSize = image.texture.get_size()
	if _auto_resize_image: 
		image.region_rect = Rect2(Vector2.ZERO,imageSize); 
		pivot_offset = imageSize*0.5
		image.pivot_offset = pivot_offset

func _on_image_changed() -> void:
	image.texture_changed.connect(_on_texture_changed)
	_update_animation_image()
#endregion


##Remove the Sprite from the scene. The same as using [code]get_parent().remove_child(self)[/code]
func kill() -> void: if parent: parent.remove_child(self)

func screenCenter(type: StringName = 'xy') -> void: ##Move the sprite to the center of the screen
	var viewport = get_viewport(); if !viewport: return
	var midScreen: Vector2 = viewport.size*0.5
	match type:
		&'xy': _position = midScreen - (pivot_offset*scale)
		&'x': _position.x = midScreen.x - (pivot_offset.x * scale.x)
		&'y': _position.y = midScreen.y - (pivot_offset.y * scale.y)

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"texture",&"position",&"camera",&"scale",&"rotation",\
		&"_real_offset",&"_scroll_offset",&"_real_scroll_factor",\
		&"_graphic_offset",&"_graphic_scale": 
			property.usage = PROPERTY_USAGE_NONE
		_: super._validate_property(property)
func _property_get_revert(property: StringName) -> Variant:
	match property:
		&'scrollFactor': return Vector2.ONE
		&'velocity',&'acceleration',&'offset': return Vector2.ZERO
	return null

func _get_property_list() -> Array[Dictionary]:
	return [
		{"name": "x", "type": TYPE_FLOAT},{"name": "y","type": TYPE_FLOAT},
		{"name": "flipX", "type": TYPE_BOOL},{"name": "flipY","type": TYPE_BOOL},
		{"name": "texture", "type": TYPE_OBJECT}
	]
