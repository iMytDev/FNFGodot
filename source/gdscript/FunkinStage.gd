class_name FunkinStage extends Resource
static func loadStage(path: String) -> Dictionary:
	var j = Paths.loadJsonNoCache(path); 
	if j: fixStageJson(j)
	return j

static func fixStageJson(json: Dictionary) -> Dictionary:
	for i in json.get("characters",[]):
		var char_data = json.characters[i]
		char_data.position = Vector2(char_data.position[0],char_data.position[1])
		if char_data.has("cameraOffsets"): char_data.cameraOffsets = Vector2(char_data.cameraOffsets[0],char_data.cameraOffsets[1])
		else: char_data.cameraOffsets = Vector2.ZERO
	json.merge(getStageBase(),false)
	return json

static var dance_sprites: Array
static func loadStageSprites(json: Dictionary) -> void:
	if !json: return
	var props = json.get('props'); if !props: return
	
	for data in props:
		var name = data.get('name','')
		var image = data.get('assetPath')
		var has_anim = !!data.get('animations')
		var position = data.get('position'); 
		if position: position = Vector2(position[0],position[1])
		else: position = Vector2.ZERO
		
		var sprite: FunkinSprite2D
		if has_anim: sprite = FunkinGD.makeAnimatedSprite(name,image,position.x,position.y)
		else: sprite = FunkinGD.makeSprite(name,image,position.x,position.y)
		
		_set_sprite_properties_from_data(sprite,data)
		FunkinGD.addSprite(sprite,data.get('front',false))
		
		if image.begins_with("#"): sprite.modulate = Color(image);
		else: sprite.image.texture = Paths.texture(image)
		
		if has_anim: _load_sprite_animations(sprite, data)
		
		

static func _set_sprite_properties_from_data(sprite: FunkinSprite2D, data: Dictionary):
	var scale = data.get('scale'); 
	if scale: sprite.scale = Vector2(scale[0],scale[1])
	
	var scroll = data.get('scroll');
	if scroll: FunkinParallax.set_parallax(sprite, Vector2(scroll[0],scroll[1]))
	
	sprite.antialiasing = !data.get('isPixel',false)
	sprite.modulate.a = data.get('alpha',1.0)

static func _load_sprite_animations(sprite: FunkinAnimatedSprite2D, data: Dictionary):
	for anim in data.animations:
		var anim_name = anim.get('name','')
		var fps = anim.get('frameRate',24)
		var looped = anim.get('looped',false)
		var indices = anim.get('frameIndices')
		var offsets = anim.get('offsets'); 
		offsets = Vector2(offsets[0],offsets[1]) if offsets else Vector2.ZERO
		
		var prefix = anim.get('prefix')
		if prefix: 
			if indices: sprite.animation.add_animation_by_prefix(anim_name,anim.prefix,fps,looped,indices)
			else: sprite.animation.add_animation_by_prefix(anim_name,anim.prefix,fps,looped)
		elif indices: sprite.animation.add_frame_animation(anim_name,indices)
		
		sprite.animation.add_animation_offset(anim_name,offsets)
	
	var startAnim = data.get('startingAnimation'); if startAnim: sprite.animation.play(startAnim,true)
		
	if sprite.animation.has_any_animations([&'danceLeft',&'danceRight']): sprite.set_meta(&"has_dance_anim",true)
	
	var danceEvery = data.get('danceEvery')
	if danceEvery: sprite.set_meta(&"danceEvery",danceEvery)

static func getStageBase() -> Dictionary:
	return {
		&"cameraZoom": 1.0,
		&"cameraSpeed": 1.0,
		&"props": [],
		&"hide_girlfriend": false,
		&"isPixelStage": false,
		&"characters": {
			&"gf": { &"position": Vector2(808.5, 854), &"cameraOffsets": Vector2.ZERO},
			&"dad": {&"position": Vector2(290.5, 869),&"cameraOffsets": Vector2.ZERO},
			&"bf": {&"position": Vector2(1297.5, 871),&"cameraOffsets": Vector2.ZERO}
		},
		&"directory": ""
	}

static func getStageBaseJson() -> Dictionary:
	return {
		&"cameraZoom": 1.0,
		&"cameraSpeed": 1.0,
		&"props": [],
		&"hide_girlfriend": false,
		&"isPixelStage": false,
		&"characters": {
			&"gf": { &"position": [808.5, 854], &"cameraOffsets": [0.0,0.0]},
			&"dad": {&"position": [290.5, 869],&"cameraOffsets": [0.0,0.0]},
			&"bf": {&"position": [1297.5, 871],&"cameraOffsets": [0.0,0.0]}
		},
		&"directory": ""
	}
