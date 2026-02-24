@tool
class_name SparrowMeshInstance3D extends MeshInstance3D
const deg_90 = deg_to_rad(90)

@export var flip_h: bool:
	set(val): flip_h = val; _update_region()

@export var flip_v: bool:
	set(val): flip_v = val; _update_region()

@export var texture: Texture2D:
	set(val): 
		if texture == val: return
		mesh.material.albedo_texture = val; 
		_tex_size = val.get_size() if val else Vector2.ZERO
		pivot_offset = Vector2.ZERO
		_update_region()
		texture_changed.emit()
	get(): return mesh.material.albedo_texture
	
var _tex_size: Vector2
var frameData: Rect2:
	set(val): frameData = val; _update_region_area()

@export_range(0.0025,0.3,0.0025) var pixel_size: float = 0.0025:
	set(val): pixel_size = val; _update_region_area()

@export var region_rect: Rect2:
	set(val):
		region_rect = val; _update_region()
		if !pivot_offset: pivot_offset = region_rect.size*0.5*pixel_size

@export var rotated: bool:
	set(val): rotated = val; rotation.z = deg_90 if val else 0.0; _update_region()

@export_storage var pivot_offset: Vector2 = Vector2.ZERO:
	set(val): pivot_offset = val; _update_uv()

signal texture_changed()
func _init() -> void:
	mesh = QuadMesh.new(); 
	mesh.material = SparrowMeshMaterial.new(); 

func _ready() -> void: _update_region()

func _update_region(): _update_uv(); _update_region_area()

func _update_uv():
	if !texture: return
	var rect = region_rect
	
	var size_div = region_rect.size / _tex_size
	var _pos_div = rect.position / _tex_size
	
	
	if _is_absolute_flipped_h(): _pos_div.x -= 1.0 - size_div.x; size_div.x = -size_div.x
	if _is_absolute_flipped_v(): _pos_div.y -= 1.0 - size_div.y; size_div.y = -size_div.y
	
	mesh.material.uv1_scale.x = size_div.x
	mesh.material.uv1_scale.y = size_div.y
	
	mesh.material.uv1_offset.x = _pos_div.x
	mesh.material.uv1_offset.y = _pos_div.y
	
	mesh.size = region_rect.size * pixel_size

func _is_absolute_flipped_h(): return flip_v if rotated else flip_h
func _is_absolute_flipped_v(): return flip_h if rotated else flip_v

func _update_region_area(): 
	var off: Vector3 = Vector3.ZERO
	
	# Removes mesh from center
	off.x += mesh.size.x * 0.5
	off.y -= mesh.size.y * 0.5
	
	
	
	var frame_offset = frameData.position * pixel_size
	if rotated: 
		#off.x += pivot_offset.y
		#off.y += pivot_offset.x
		
		off.x += frame_offset.x - mesh.size.x
		off.y -= frame_offset.y
		
		if _is_absolute_flipped_h(): off.x = -off.x + pivot_offset.x * 2.0
		if _is_absolute_flipped_v(): off.y = -off.y + pivot_offset.y * 2.0
	else:
		off.x += frame_offset.x
		off.y -= frame_offset.y
		
		if _is_absolute_flipped_h(): off.x = -off.x + pivot_offset.x * 2.0
		if _is_absolute_flipped_v(): off.y = -off.y + pivot_offset.y * 2.0
		
	#if _is_absolute_flipped_h(): off.x *= -1.0
	#if _is_absolute_flipped_v(): off.y *= -1.0
	
	mesh.center_offset = off
