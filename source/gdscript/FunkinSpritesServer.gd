class_name FunkinSpritesServer extends FunkinInternal
static var spritesCreated: Dictionary[StringName,Node] ##Sprites created using [method makeSprite] or [method makeAnimatedSprite] methods.


static func makeSprite(tag: StringName, path: Variant = null, x: float = 0, y: float = 0) -> FunkinSprite2D: ##Creates a [Sprite].
	var sprite = FunkinSprite2D.new(path); 
	sprite.position = Vector2(x,y)
	if tag: sprite.name = tag; 
	_insert_sprite(tag,sprite)
	return sprite

static func makeAnimatedSprite(tag: StringName, path: Variant = null, x: float = 0, y: float = 0) -> FunkinSprite2D: ##Creates a animated [Sprite].
	var sprite = FunkinAnimatedSprite2D.new(path); 
	sprite.position = Vector2(x,y)
	if tag: sprite.name = tag; 
	_insert_sprite(tag,sprite)
	return sprite

static func makeGraphic(object: String, width: float = 0.0,height: float = 0.0,color: Variant = Color.BLACK) -> SolidNode2D:
	var obj = SolidNode2D.new()
	obj.size = Vector2(width,height)
	obj.modulate = FunkinGD._get_color(color)
	_insert_sprite(object,obj)
	return obj

static func loadGraphic(object: Variant, image: Variant, width: float = -1, height: float = -1) -> void: ##Load image in the sprite.
	object = FunkinProperty._find_object(object); if !object: return
	
	if object is FunkinSprite2D: object = object.image
	var tex = Paths.texture(image)
	object.texture = tex
	if not (object is Sprite2D or object is NinePatchRect): return
	if width != -1: object.region_rect.size.x = width
	if height != -1: object.region_rect.size.y = height


##Changes the image region size of the sprite.[br]
static func setGraphicSize(object: Variant, sizeX: float = -1, sizeY: float = -1) -> void:
	object = FunkinProperty._find_object(object); if !object: return
	
	if object is FunkinSprite2D: object = object.image
	if !object is Sprite2D and !object is NinePatchRect or !object.texture: return
	
	var tex_size = object.texture.get_size()
	var size = Vector2(
		tex_size.x if sizeX == -1 else sizeX,
		tex_size.y if sizeY == -1 else sizeY
	)
	object.region_rect.size = size

static func addSprite(object: Variant, front: bool = false, camera: Variant = &"camGame") -> void: ##Add [Sprite] to game.
	object = FunkinProperty._find_object(object); if !object: return
	camera = FunkinCameraServer.camera_get(camera); if !camera: return
	camera.add(object,front)

static func removeSprite(object: Variant, delete: bool = false) -> void:
	var node = FunkinProperty._find_object(object); if !node: return
	var tag: StringName = object.name if object is Node else object
	
	if node.is_inside_tree(): node.get_parent().remove_child(node)
	if delete: spritesCreated.erase(tag)

static func insertSpriteToCamera(object: Variant, at: int, camera: Variant = &"game"): ##Insert a [Sprite] to a [param camera] in a specific position.
	object = FunkinProperty._find_object(object); if !object: return
	camera = FunkinCameraServer.camera_get(camera)
	if camera: camera.insert(at, object)

static func insertSpriteToGroup(object: Variant, group: Variant, at: int): ##Insert a [Sprite] to a [param camera] in a specific position.
	object = FunkinProperty._find_object(object); if !object: return
	group = FunkinProperty._find_object(group); if !group: return
	group.insert(at, object)

static func screenCenter(object: Variant, type: StringName = &"xy"):
	object = FunkinProperty._find_object(object); if !object: return
	var center = (object.get_viewport().size*0.5 if object.is_inside_tree() else ScreenUtils.screenCenter)
	if object is FunkinSprite2D: center -= object.pivot_offset
	else:
		var tex = object.get(&'texture')
		var size = tex.get_size() if tex else object.get(&'size')
		if size: center += size*0.5
	
	match type:
		&'x': object.position.x = center.x
		&'y': object.position.y = center.y
		_: object.position = center

##Set the scroll factor from the sprite.[br]
##This makes the object have a depth effect, [u]the lower the value, the greater the depth[/u].
static func setScrollFactor(object: Variant, x: float = 1, y: float = 1) -> void:
	FunkinParallax.set_parallax(FunkinProperty._find_object(object),Vector2(x,y))


static func set_object_camera(object: Variant, camera: Variant = 'game'):##Set the object camera.
	object = FunkinProperty._find_object(object); if !object: return
	var cam: Node = FunkinCameraServer.camera_get(camera); if !cam: return
	if object is FunkinSprite2D: object.set(&'camera',cam)
	else: cam.add(object)

##Set the order of the object in the screen.
static func setObjectOrder(object: Variant, order: int)  -> void: ##Set the order of the object in the screen.
	object = FunkinProperty._find_object(object); if !object: return
	var parent = object.get_parent(); 
	if !parent:
		debug_message('Error on setObjectOrder: "'+ object.name+'" must be added to scene before setting his order.')
		return
	var count = parent.get_child_count()
	parent.move_child(object,clampi(order,-count,count))

static func getObjectOrder(object: Variant) -> int: ##Returns the object's order.
	object = FunkinProperty._find_object(object); if !object: return -1
	return object.get_index() if object is Node else -1

static func get_midpoint(object: Variant) -> Vector2:
	object = FunkinProperty._find_object(object)
	if object is FunkinSprite2D: return object.getMidpoint()
	if (object is CanvasItem) and object.get(&'texture'): return object.position + (object.texture.get_size())
	return Vector2.ZERO

static func get_midpoint_3d(object: Variant) -> Vector3:
	object = FunkinProperty._find_object(object)
	if !object: return Vector3.ZERO
	if object is Sprite3D: 
		if !object.centered and object.texture: return object.position + object.texture.get_size() * 0.5
	return object.position
##Scale a object.
static func scale(object: Variant, x: float = 1.0, y: float = 1.0) -> void:
	object = FunkinProperty._find_object(object); if !object: return
	object.scale = Vector2(x,y)

static func _insert_sprite(tag: StringName, object: Node) -> void: 
	var sprite = spritesCreated.get(tag)
	if sprite and sprite is Node: sprite.queue_free()
	spritesCreated[tag] = object

static func _get_texture(image: Variant) -> Texture:
	if image is Texture: return image
	if image is String or image is StringName: return Paths.texture(image)
	return null
	
static func clear(): spritesCreated.clear()
