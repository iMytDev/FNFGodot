extends Sprite2D

func _init() -> void: centered = false

func _ready() -> void:
	texture_changed.connect(_texture_changed)
	ScreenUtils.main_window.size_changed.connect(_texture_changed)
	_texture_changed()

func _exit_tree() -> void:
	texture_changed.disconnect(_texture_changed)
	ScreenUtils.main_window.size_changed.disconnect(_texture_changed)

func get_uniform_fit_scale(size: Vector2, to: Vector2, max: bool = false) -> Vector2:
	var _size = to / size
	var val: float
	if max: val = maxf(_size.x,_size.y)
	else: val = minf(_size.x,_size.y)
	return Vector2(val,val)

func _texture_changed() -> void:
	if !texture: return
	scale = get_uniform_fit_scale(texture.get_size(), ScreenUtils.screenSize, true)


func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"scale": property.usage = PROPERTY_USAGE_NONE
