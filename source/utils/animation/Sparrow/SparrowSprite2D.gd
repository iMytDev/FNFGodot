@tool
class_name SparrowSprite extends Node2D
const deg_90 = deg_to_rad(270)

@export var texture: Texture2D: set = set_texture
@export var flip_h: bool: set = set_flip_h
@export var flip_v: bool: set = set_flip_v


var rotated: bool: set = set_rotated


@export var region_rect: Rect2: set = set_region
@export var region_rect_offset: Rect2 = Rect2():
	set(val): region_rect_offset = val; if use_region_offset: queue_redraw()

@export var use_region_offset: bool = false:
	set(val): use_region_offset = val; queue_redraw()

var frameData: Rect2: set = _set_frame_data
var pivot_offset: Vector2: set = set_pivot_offset #Is set in Anim.gd
var _pivot_set: bool
var _flip_offset: Vector2
var _draw_scale: Vector2 = Vector2.ONE


signal texture_changed()
#region Setters
func set_texture(tex: Texture2D): 
	if tex == texture: return
	texture = tex
	_pivot_set = false
	rotated = false
	texture_changed.emit();

func set_flip_h(f: bool) -> void: 
	if flip_h == f: return 
	flip_h = f; _draw_scale.x = -1.0 if f else 1.0; 
	_update_flip_offset()

func set_flip_v(f: bool) -> void: 
	if flip_v == f: return
	flip_v = f; _draw_scale.y = -1.0 if f else 1.0; _update_flip_offset();

func set_rotated(r: bool) -> void: 
	if rotated == r: return
	rotated = r; queue_redraw()

func set_pivot_offset(p: Vector2): pivot_offset = p; _update_flip_offset();

func _set_frame_data(off: Rect2): frameData = off; queue_redraw()

func set_region(r: Rect2) -> void: 
	region_rect = r; 
	if !_pivot_set: pivot_offset = region_rect.size*0.5; if pivot_offset: _pivot_set = true
	queue_redraw()
	item_rect_changed.emit()


#endregion
func _update_flip_offset() -> void:
	_flip_offset = Vector2(
		pivot_offset.x*2.0 if flip_h else .0, 
		pivot_offset.y*2.0 if flip_v else .0
	)
	queue_redraw()

func _draw() -> void:
	if !texture: return
	var rect = region_rect
	var _scale_draw = _draw_scale
	var offset: Vector2 = -_flip_offset
	
	if rotated: 
		offset += Vector2(
			frameData.position.y,
			-frameData.position.x + rect.size.x
		)
		draw_set_transform(offset * _scale_draw, deg_90, Vector2(_scale_draw.y, _scale_draw.x))
	else: 
		offset += frameData.position
		draw_set_transform(offset * _scale_draw, 0.0, _scale_draw)
	
	if use_region_offset: _draw_with_offset(rect, _scale_draw)
	else: draw_texture_rect_region(texture, Rect2(Vector2.ZERO, rect.size), rect, Color.WHITE)

func _draw_with_offset(rect: Rect2, scale_draw: Vector2 = Vector2.ONE):
	var real_size = rect.size + region_rect_offset.size
	var offset_mod = Vector2(
		wrapf(region_rect_offset.position.x, 0.0, rect.size.x),
		wrapf(region_rect_offset.position.y, 0.0, rect.size.y)
	)
	
	var div = Vector2.ZERO
	if rect.size.x: div.x = (real_size.x + absf(offset_mod.x)) / rect.size.x
	if rect.size.y: div.y = (real_size.y + absf(offset_mod.y)) / rect.size.y
	var size = rect.size
	var _position = rect.position
	
	var _cur_tex_pos: Vector2 = Vector2.ZERO
	var cur_offset: Vector2 = offset_mod
	var pos_y: float = 0.0
	
	while pos_y < div.y:
		var height: float = size.y * minf(div.y - pos_y, 1.0) - cur_offset.y
		var pos_x: float = 0.0
		cur_offset.x = offset_mod.x
		while pos_x < div.x:
			var width = size.x * minf(div.x - pos_x,1.0) - cur_offset.x
			var view_position = _cur_tex_pos
			var view_size: Vector2 = Vector2(width,height) * scale_draw
			draw_texture_rect_region(
				texture,
				Rect2(
					view_position, 
					view_size
				),
				Rect2(_position + cur_offset,view_size),Color.WHITE
			)
			_cur_tex_pos.x += width
			cur_offset.x = 0.0
			pos_x += 1.0
		_cur_tex_pos.x = 0.0
		_cur_tex_pos.y += height
		cur_offset.y = 0.0
		pos_y += 1.0
