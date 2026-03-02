class_name FunkinAnimatedSprite2D extends FunkinSprite2D

var animation: Anim = Anim.new():
	set(val): animation = val; _set_animation_resource()

var _pivot_set: bool:
	set(val): 
		if _pivot_set == val: return
		_pivot_set = val
		if val: image.item_rect_changed.disconnect(_check_image_pivot)
		else: image.item_rect_changed.connect(_check_image_pivot)

func _init(texture: Variant = null) -> void:
	super(texture)
	_auto_resize_image = false
	_set_animation_resource()
	image.item_rect_changed.connect(_check_image_pivot)

func _on_texture_changed() -> void: super(); _pivot_set = false

func _check_image_pivot() -> void: 
	pivot_offset = image.region_rect.size * 0.5
	if pivot_offset: _pivot_set = true

func _process(delta: float) -> void: animation.process_frame(delta)

#region Animation Methods
func _on_animation_updated(anim: StringName) -> void:
	var data = animation.animationsArray[anim]
	if data.has_meta(&"offset"): offset = data.get_meta(&"offset"); 

func _set_animation_resource() -> void:
	animation.animation_updated.connect(_on_animation_updated); 
	animation.node_to_animate = image;

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"animation": property.usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_STORAGE
	super(property)
#endregion
