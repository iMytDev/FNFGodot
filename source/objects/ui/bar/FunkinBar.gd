@tool
@icon("res://icons/process_bar_2d.svg")

class_name FunkinBar extends Node2D
@export var bg: BarResource = BarResource.new()

@export var margin_left: float = 4.0:
	set(val): margin_left = val; _update_bar()
@export var margin_right: float = 4.0:
	set(val): margin_right = val; _update_bar()
@export var margin_top: float = 4.0:
	set(val): margin_top = val; _update_bar()
@export var margin_bottom: float = 4.0:
	set(val): margin_bottom = val; _update_bar()

@export var leftBar: BarResource = BarResource.new()
@export var rightBar: BarResource = BarResource.new()

@export_range(0.0,1.0,0.001) 
var progress: float = 0.5: set = set_progress

var progress_position: Vector2

@export var flip: bool = false: 
	set(f): flip = f; _update_bar()

@export var behind: bool = true:
	set(val): behind = val; queue_redraw()

@export var region_filled: Vector2

@export var centered: bool = true:
	set(val): centered = val; queue_redraw()
	
var fill_bars_size: Vector2 = Vector2.ZERO
var bar_size: Vector2: set = set_bar_size

func _init() -> void: 
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	bg.changed.connect(queue_redraw)
	bg.texture_changed.connect(func():
		bar_size = bg.texture.get_size() if bg.texture else Vector2.ZERO
	)
	leftBar.changed.connect(queue_redraw)
	rightBar.color = Color.DIM_GRAY
	rightBar.changed.connect(queue_redraw)
	bg.texture = Paths.texture(&"healthBar")

func _ready(): _update_bar_fill_size()

#region Updaters
func _update_bar() -> void:
	if !is_node_ready(): return
	progress_position = get_process_position()
	queue_redraw()

func _update_bar_fill_size():
	if !is_node_ready(): return
	fill_bars_size = Vector2(
		margin_left + margin_right,
		margin_top + margin_bottom
	)
	_update_bar()
#endregion

func set_progress(p: float):
	p = clampf(p,0,1.0)
	if progress == p: return
	progress = p; _update_bar()

func get_process_position(process: float = progress) -> Vector2:
	var _process = Vector2(bar_size.x*process,0.0)*scale
	if centered: _process -= bar_size * 0.5
	return _process.rotated(rotation) if rotation else _process
	
func set_bar_size(size: Vector2): bar_size = size; _update_bar()



#region Draw Methods
func _draw() -> void:
	if behind:
		_draw_filled_bar(leftBar,flip)
		_draw_filled_bar(rightBar,!flip)
		_draw_bg()
	else:
		_draw_bg()
		_draw_filled_bar(leftBar,flip)
		_draw_filled_bar(rightBar,!flip)

func _draw_bg():
	if !bg.visible or !bg.texture: return
	_update_draw_transform(bg)
	if bg.texture: draw_texture(bg.texture,bg.position)

func _draw_filled_texture(bar: BarResource, right: bool = false):
	var tex = bar.texture
	var size = tex.get_size()
	var _scale = bar_size / tex.get_size()
	var rect = Rect2(Vector2(margin_left,margin_top),size)
	rect.size.x -= margin_right-margin_left
	rect.size.y -= margin_bottom-margin_top
	
	var fill = rect.size.x * progress
	if right: 
		rect.position.x += fill
		rect.size.x *= (1.0 - progress) * -1.0; 
	else: rect.size.x = fill
	draw_texture_rect(tex,rect,true);
	
func _draw_filled_rect(bar: BarResource, right: bool = false):
	var color = bar.color
	var size = bar_size
	size -= Vector2(margin_left,margin_top)
	size -= Vector2(margin_right,margin_bottom)
	var width = size.x * progress
	if right: 
		draw_rect(
			Rect2(
				Vector2(width+margin_left,margin_top) + bar.position,
				Vector2(size.x * (1.0 - progress),size.y)
			),
			color
		); return
	draw_rect(Rect2(
		Vector2(margin_left,margin_top) + bar.position,
		Vector2(width,size.y)),
		color
	);

func _update_draw_transform(bar: BarResource):
	var _pos = bar.position
	if centered: _pos -= bar_size * 0.5
	draw_set_transform(_pos,0.0,bar.scale)
func _draw_filled_bar(bar: BarResource, right: bool = false):
	if !bar.visible: return
	
	_update_draw_transform(bar)
	if bar.texture: _draw_filled_texture(bar, right)
	else: _draw_filled_rect(bar, right)

#endregion
