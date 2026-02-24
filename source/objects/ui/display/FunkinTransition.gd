@tool
class_name FunkinTransition extends Sprite2D

func _init() -> void:
	name = &'Transition'
	centered = false
	z_index = 1
	texture = GradientTexture2D.new()
	texture.gradient = Gradient.new()
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(0.5,1)
	
	texture.gradient.set_color(0, Color())
	texture.gradient.set_color(1, Color(Color.BLACK,0.0))
	_update_size()

func _update_size() -> void:
	texture.width = ScreenUtils.screenWidth
	texture.height = ScreenUtils.screenHeight * 2.0

func start_trans(auto_exit: bool = true) -> PropertyTweener:
	flip_v = false
	_update_size()
	offset.y = -texture.height * 1.5
	var tween = _scroll_down()
	if auto_exit: tween.finished.connect(remove_trans)
	return tween

func remove_trans(auto_delete: bool = true) -> PropertyTweener:
	offset.y = -texture.height * 0.5
	flip_v = true
	_update_size()
	var tween = _scroll_down(texture.height * 0.5)
	if auto_delete: tween.finished.connect(queue_free)
	return tween

func _scroll_down(scroll_to: float = 0.0) -> PropertyTweener:
	var tween: Tween = create_tween()
	return tween.tween_property(self,^'offset:y',scroll_to,0.7)

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"texture",&"centered": property.usage = PROPERTY_USAGE_NONE


static func create_transition(at: Node = Global.root):
	if !at: push_error('Error on "do_transition": "node" is invalid.'); return
	var trans = FunkinTransition.new()
	at.add_child(trans)
	return trans
