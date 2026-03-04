@tool
class_name CharacterSprite3D extends CharacterBase3D 
const DEFAULT_CAM_POS = Vector3(0.0, 0.2, 2.0)

var image = SparrowSprite3D.new()
var material: SparrowMeshMaterial = image.mesh.mesh.material

@export_placeholder("bf") var curCharacter: String

@export var charType: Character.Type = Character.Type.BF:
	set(val): charType = val; _update_character_flip()

@export_tool_button("Load Character") var l = loadCharacter

@export var jsonScaleMult: float = 1.0:
	set(val): jsonScaleMult = val; _update_character_scale()

@export var animation: Anim = Anim.new():
	set(val): animation = val; _set_animation_resource()

@export_category("Material")
@export var self_modulate: Color:
	set(val): material.albedo_color = val
	get: return material.albedo_color

@export var unshaded: bool:
	set(val): 
		unshaded = val
		if unshaded: material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		else: material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

@export_category("Transform3D")
@export var offset: Vector2 = Vector2.ZERO:
	set(val): offset = val; _update_offset()

@export_storage var offset_follow_flip: bool = true
@export_storage var offset_follow_scale: bool = true ##If [code]true[/code], the offset will be multiplied by the sprite scale when set.
@export_storage var offset_follow_rotation: bool = true ##If [code]true[/code], the offset will follow the rotation.

#Storage Variables
@export_storage var pivot_offset: Vector2:
	set(val): image.mesh.pivot_offset = val;
	get: return image.mesh.pivot_offset

func _init() -> void: 
	_set_animation_resource(); 
	add_child(image, false, Node.INTERNAL_MODE_FRONT); 

func _update_offset() -> void: 
	image.position.x = -offset.x + data.positionArray.x * image.mesh.pixel_size; 
	image.position.y = offset.y - data.positionArray.y * image.mesh.pixel_size;

func _process(delta: float) -> void: super(delta); animation.process_frame(delta)

#region Animation Methods
func _set_animation_resource() -> void:
	animation.node_to_animate = image.mesh
	animation.animation_started.connect(_on_animation_started); 
	animation.animation_updated.connect(_on_animation_updated); 

func _on_animation_updated(anim: StringName) -> void:
	var data = animation.animationsArray[anim]
	if !data.has_meta(&"offset"): return 
	var off = data.get_meta(&"offset"); 
	if off == null: return
	if offset_follow_flip:
		if image.mesh.flip_h: off.x *= -1.0
		if image.mesh.flip_v: off.y *= -1.0
	offset = off * image.mesh.pixel_size
#endregion

#region Character Methods
##Load Character. Returns a [Dictionary] with the json found data.
func loadCharacter(char_name: StringName = curCharacter): Character.load_character_json_from_name(self,char_name)

func _on_data_set(d: CharacterData) -> void:
	super(d);
	if data.isPixel: 
		image.mesh.mesh.material.texture_filter = StandardMaterial3D.TEXTURE_FILTER_NEAREST
	else: 
		image.mesh.mesh.material.texture_filter = StandardMaterial3D.TEXTURE_FILTER_LINEAR
	
	offset_follow_flip = data.offset_follow_flip
	offset_follow_scale = data.offset_follow_scale
	offset_follow_rotation = true
	image.texture = Paths.texture(data.imageFile)
	
	animation.animationsArray = data.animationsArray
	
	_update_character_flip()
	_update_character_scale()
	_update_offset()
	notify_property_list_changed()
	

func dance() -> void: ##Make character returns to his dance animation.
	if data.hasDanceAnim: 
		animation.play(&'danceRight' if danced else &'danceLeft'); danced = !danced
	else: animation.play('idle'+idleSuffix,forceDance)
	super()

func _update_character_scale() -> void: 
	var s = data.jsonScale * jsonScaleMult; scale = Vector3(s,s,s)

func _update_character_flip() -> void: image.flip_h = !data.flipX if Character.isPlayer(self) else data.flipX
#endregion

#region Camera Methods
func getMidpoint() -> Vector3:
	var off: Vector3 =  Vector3(data.positionArray.x, -data.positionArray.y, 0.0) * scale * image.mesh.pixel_size
	if !rotation.y: return position + off
	
	var rotated = Vector2(off.x,off.z).rotated(rotation.y)
	off.x = rotated.x
	off.z = -rotated.y
	return position + off

func getCameraPosition() -> Vector3:
	var center = getMidpoint()
	var cam_off = Vector3(
		data.cameraPosition.x * image.mesh.pixel_size, 
		data.cameraPosition.y * image.mesh.pixel_size, 
		0.0
	) 
	match charType:
		Character.Type.OPPONENT: cam_off.x += 0.3
		Character.Type.BF: 
			cam_off.x *= -1.0
			cam_off.x -= 0.3
	cam_off.x += pivot_offset.x
	cam_off.y -= pivot_offset.y
	cam_off += DEFAULT_CAM_POS
	cam_off *= scale
	if rotation.y: 
		var rotated = Vector2(cam_off.x,cam_off.z).rotated(rotation.x)
		cam_off.x = rotated.x
		cam_off.z = -rotated.y
	return center + cam_off

func getCameraRotation() -> Vector3: return rotation
#endregion

#region Property Methods
func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"offset": property.usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
		_: Character.validate_character_property(property)
#endregion
