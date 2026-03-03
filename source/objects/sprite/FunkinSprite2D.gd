@icon("res://icons/HaxeFlixel_logo.svg") @tool
class_name FunkinSprite2D extends PivotNode2D

#region Offset
@export_category("Offset")
@export var offset: Vector2: 
	set(val): 
		if val == offset: return; 
		offset = val; _update_real_offset(); 

##If [code]true[/code], the offset will follow the sprite flips.[br][br]
##[b]Example[/b]: if the sprite has flipped horizontally, the [param offset.x] will be inverted horizontally(x)
@export var offset_follow_flip: bool
@export var offset_follow_scale: bool ##If [code]true[/code], the offset will be multiplied by the sprite scale when set.
@export var offset_follow_rotation: bool ##If [code]true[/code], the offset will follow the rotation.
#endregion

var parent: Node

#region Velocity Vars
@export_category("Velocity")
@export var acceleration: Vector2 = Vector2.ZERO:##This will accelerate the velocity from the value setted.
	set(val): acceleration = val; _check_velocity() 

@export var velocity: Vector2 = Vector2.ZERO:  ##Will add velocity from the position, making the sprite move.
	set(val): velocity = val; _check_velocity() 

var _accelerating: bool
@export var maxVelocity: Vector2 = Vector2(999999,99999) ##The limit of the velocity, set [Vector2](-1,-1) to unlimited.
#endregion

var _real_offset: Vector2: set = _set_real_offset

#region Images Properties
##The Node that will be animated. [br]
##Can be a [Sprite2D] with [member Sprite2D.region_enabled] enabled
## or a [NinePatchRect]
var image: SparrowSprite = SparrowSprite.new():
	set(f): return

##If [code]true[/code], 
##the region_rect of the [param image] will be resized automatically 
##for his texture size every time it's changes.
var _auto_resize_image: bool = true

@export_category("Image")
var imageSize: Vector2 ##The texture size of the [member image]
#endregion


#region Native Methods
func _init(texture: Variant = null): 
	super(); 
	image.texture_changed.connect(_on_texture_changed)
	set_texture(texture); 
	add_child(image,false,Node.INTERNAL_MODE_FRONT)

func _update_pivot() -> void: super(); _update_real_offset()
func _enter_tree() -> void: parent = get_parent();
func _exit_tree() -> void: parent = null;
func _process(delta: float) -> void:
	if _accelerating: _add_velocity(delta)
#endregion

#region Velocity Methods
func _check_velocity() -> void: _accelerating = acceleration != Vector2.ZERO or velocity != Vector2.ZERO

func _add_velocity(delta: float) -> void: 
	if Engine.is_editor_hint(): return
	velocity += acceleration * delta; position += velocity.clamp(-maxVelocity,maxVelocity) * delta
#endregion

#region Setters
func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"material": image.material = value;
		&"texture": image.texture = value;
		&"region_rect": image.region_rect = value;
		&"antialiasing": image.texture_filter = TEXTURE_FILTER_LINEAR if value else TEXTURE_FILTER_NEAREST
		&"flipX": image.flip_h = value; 
		&"flipY": image.flip_v = value; 
		_: return false
	return true

func _set_real_offset(val: Vector2) -> void:
	if val == _real_offset: return
	_canvas_transform_offset -= val - _real_offset; _real_offset = val
#endregion

func _get(property: StringName) -> Variant:
	match property:
		&"material": return image.material;
		&"texture": return image.texture;
		&"antialiasing": return image.texture_filter == TEXTURE_FILTER_NEAREST
		&"region_rect": return image.region_rect
		&"flipX": return image.flip_h;
		&"flipY": return image.flip_v;
	return

func getMidpoint() -> Vector2: return position + pivot_offset ##Returns the [u]center[/u] of the sprite in the scene.

#region Image Setters
func set_texture(tex: Variant):
	if !tex: image.texture = null; return;
	image.texture = tex if tex is Texture2D else Paths.texture(tex)
#endregion

#region Updaters
func _update_real_offset() -> void: _real_offset = _get_real_offset()
func _get_real_offset() -> Vector2:
	var off = offset
	if offset_follow_scale: off *= scale * image.scale
	if offset_follow_flip:
		if image.flip_h: off.x = -off.x 
		if image.flip_v: off.y = -off.y 
	if offset_follow_rotation and rotation: off = off.rotated(rotation)
	return off
#endregion

#region Change Signals
func _on_texture_changed() -> void:
	if !image.texture: imageSize = Vector2.ZERO; pivot_offset = imageSize; return
	imageSize = image.texture.get_size()
	if _auto_resize_image: image.region_rect = Rect2(Vector2.ZERO,imageSize); pivot_offset = imageSize * 0.5

#endregion

func _get_pivot() -> Vector2: return super() * image.scale

##Remove the Sprite from the scene. The same as using [code]get_parent().remove_child(self)[/code]
func kill() -> void: if parent: parent.remove_child(self)

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"texture": property.usage = PROPERTY_USAGE_EDITOR

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&'velocity',&'acceleration',&'offset': return Vector2.ZERO
	return null

func _get_property_list() -> Array[Dictionary]:
	return [
		{"name": "texture", "type": TYPE_OBJECT},
		{"name": "flipX", "type": TYPE_BOOL},
		{"name": "flipY", "type": TYPE_BOOL},
		{"name": "region_rect", "type": TYPE_RECT2},
	 ]
