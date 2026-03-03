class_name FunkinGD extends FunkinInternal

#region Public Vars
@export_category('Class Vars')

static var Function_Continue: int
static var Function_Stop: int = 1

static var isStoryMode: bool
static var botPlay: bool

##Used to precache the Methods in the script, being more optimized for calling functions in [method callOnScripts]

@export_group('Game Data')
static var isPixelStage: bool

static var playAsOpponent: bool

static var lowQuality: bool: ##low quality.
	get(): return ClientPrefs.data.lowQuality

static var screenWidth: float: ##The Width of the Screen.
	get(): return ScreenUtils.screenWidth
		
static var screenHeight: float: ##The Height of the Screen.
	get(): return ScreenUtils.screenHeight

static var screenSize: Vector2i: ##The Size of the Screen.
	get(): return ScreenUtils.screenSize

static var inCutscene: bool

static var seenCutscene: bool: ##See [member PlayStateBase.seenCustscene].
	get(): return game.seenCutscene

static var inGameOver: bool = false

#region Song Data Properties
@export_category("Song Data")
static var curStage: String: 
	get(): return game.curStage

static var songName: String: ##song name.
	get(): return Conductor.songData.songName

static var songStarted: bool:
	get(): return !!Conductor.songs

static var songLength: float:
	set(val):
		if songLength == val: return
		songLength = val
		songLengthSeconds = val*0.001

static var songLengthSeconds: float:
	set(val):
		if songLengthSeconds == val: return
		songLengthSeconds = val
		songLength = val*1000.0
	
static var difficulty: String:
	get(): return game.songData.difficulty

static var mustHitSection: bool ##If the section is bf focus

static var gfSection: bool ##GF Section Focus

static var altAnim: bool ##Alt Section Animation
#endregion

#region Conductor Properties
static var bpm: float
static var stepCrochet: float
static var stepCrochetMs: float
static var crochet: float

static var curBeat: int
static var curStep: int

static var curSection: int
static var keyCount: int = 4

static var GameMode: PlayStateBase.GameMode = PlayStateBase.GameMode.MODE_2D
#endregion

#region Client Prefs Properties
@export_category("Client Prefs")
#Scroll
static var middlescroll: bool
static var downscroll: bool
static var hideHud: bool

#TimeBar
static var shadersEnabled: bool:
	get(): return ClientPrefs.data.shadersEnabled

static var version: StringName = &'1.0' ##Engine Version

static var cameraZoomOnBeat: bool = true

static var flashingLights: bool:
	get(): return ClientPrefs.data.flashingLights
#endregion


#region File Methods
static func precacheImage(path: String) -> Image: return Paths.image(path) ##Precache a image, similar to [method Paths.image]
static func precacheMusic(path: String) -> AudioStreamOggVorbis: return Paths.music(path) ##Precache a music, similar to [method Paths.music]
static func precacheSound(path: String) -> AudioStreamOggVorbis: return Paths.sound(path) ##Precache a sound, similiar to [method Paths.sound]
static func precacheVideo(path: String) -> VideoStreamTheora: return Paths.video(path) ##Precache a video file.
static func checkFileExists(path: String) -> bool: return PathsStore.file_exists(path) ##Similar to [method Paths.file_exists].
static func addCharacterToList(character: StringName) -> void: ##Precache character.
	var data: CharacterData = Character.load_character_data(character)
	if data: Paths.texture(data.imageFile) #Precache Character image
#endregion

#region Property methods
##Set a Property. If [param target] set, the function will try to set the property from this object.
static func setProperty(property: String, value: Variant, target: Variant = null) -> void: 
	if target: FunkinProperty.set_object_property_split(property.split('.'),value,target)
	else: FunkinProperty.set_property(property,value)

##Set a Property from a group member. If [param target] set, the function will try to set the property from this object.
static func setPropertyFromGroup(group: Variant, index: Variant, property: Variant, value: Variant) -> void:
	group = FunkinProperty._find_group_member(group,index); if !group: return
	FunkinProperty.set_object_property_split(property.split('.'),value,group)

static func getPropertyFromGroup(group: Variant, index: Variant, property: String = '') -> Variant: 
	group = FunkinProperty._find_group_member(group,index); if !property: return group
	return FunkinProperty.get_object_property_split(property.split('.'),group) if group else null

static func getProperty(property: String, default: Variant = null) -> Variant: 
	var value = FunkinProperty.get_property(property)
	return value if value != null else default

static func setVar(variable: Variant, value: Variant = null) -> void: modVars[variable] = value ##Set/Add a variable to [member modVars].

##Get a variable from the [member modVars].[br]
##Note: If the [param variable] is not in [member modVars], then it will return [param default].
static func getVar(variable: Variant, default: Variant = null) -> Variant: return modVars.get(variable,default)
#endregion

#region Class Methods
static func getPropertyFromClass(_class: Variant, variable: String) -> Variant:
	return FunkinProperty.get_object_property_split(variable.split('.'),FunkinProperty._find_class(_class))

static func setPropertyFromClass(_class: Variant,variable: String,value: Variant) -> void:##Set the variable of the [code]_class[/code]
	_class = FunkinProperty._find_class(_class); if _class: setProperty(variable,value,_class)
#endregion

#region Group Methods
##Add [Sprite] to a [code]group[/code] [SpriteGroup] or [Array].[br][br]
##If [code]at = -1[/code], the sprite will be inserted at the last position.
static func addSpriteToGroup(object: Variant, group: Variant, at: int = -1) -> void: FunkinGroups.add_to_group(object, group, at)
static func removeFromGroup(group: Variant, at: int) -> Variant: return FunkinGroups.remove_from_group_at(group, at)
static func createSpriteGroup(tag: String) -> SpriteGroup: return FunkinGroups.create_group(tag) ##Creates a [SpriteGroup].
#endregion


#region Timer Methods
static func runTimer(tag: StringName, time: float, loops: int = 0) -> Timer: ##Runs a timer, return the [Timer] created.
	return FunkinTimerServer.runTimer(tag, time ,loops)

static func getTimerLoops(tag: String) -> int: 
	var timer = FunkinTimerServer.timersPlaying.get(tag); 
	return timer.get_meta(&"loops") if timer else 0

static func cancelTimer(tag: String): FunkinTimerServer.cancelTimer(tag) ##Cancel Timer. See also [method runTimer].
#endregion


#region Random Methods
static func getRandomBool(chance: int = 50) -> bool: return randi_range(0,100) <= chance ##Return a random [bool].
#endregion


#region Sprite Methods
static func makeSprite(tag: StringName, path: Variant = null, x: float = 0, y: float = 0) -> FunkinSprite2D:  ##Creates a [Sprite].
	return FunkinSpritesServer.makeSprite(tag,path,x,y)

static func makeAnimatedSprite(tag: StringName, path: Variant = null, x: float = 0, y: float = 0) -> FunkinSprite2D: ##Creates a animated [Sprite].
	return FunkinSpritesServer.makeAnimatedSprite(tag,path,x,y)

static func addSprite(object: Variant, front: bool = false, camera: Variant = &"camGame") -> void: ##Add [Sprite] to game.
	FunkinSpritesServer.addSprite(object, front, camera)

##Insert a [Sprite] to a [param camera] in a specific position.
static func insertSprite(object: Variant, at: int, camera: Variant) -> void: 
	FunkinSpritesServer.insertSpriteToCamera(object, camera, at)

static func insertSpriteToGroup(object: Variant, group: Variant, at: int): ##Insert a [Sprite] to a [param camera] in a specific position.
	FunkinSpritesServer.insertSpriteToGroup(object, group, at)

##Remove [Sprite] of the game. When [code]delete[/code] is true, the sprite will be remove completely.
static func removeSprite(object: Variant, delete: bool = false) -> void:
	FunkinSpritesServer.removeSprite(object, delete)


static func makeGraphic(object: String, width: float = 0.0,height: float = 0.0,color: Variant = Color.BLACK) -> SolidNode2D:
	return FunkinSpritesServer.makeGraphic(object,width,height, color)

##Load image in the sprite.
static func loadGraphic(object: Variant, image: Variant, width: float = -1, height: float = -1): 
	FunkinSpritesServer.loadGraphic(object, image, width, height)

##Changes the image region size of the sprite.[br]
static func setGraphicSize(object: Variant, x: float = -1, y: float = -1) -> void: 
	FunkinSpritesServer.setGraphicSize(object, x, y)

##Move the [param object] to the center of the screen.[br]
##[param type] can be: [code]""xy,x,y[/code]
static func screenCenter(object: Variant, type: StringName = &'xy') -> void: FunkinSpritesServer.screenCenter(object, type)

##Scale object.
##If not [param centered], the sprite will scale from his top left corner.
static func scaleObject(object: Variant,x: float = 1.0,y: float = 1.0) -> void: 
	FunkinSpritesServer.scale(object, x ,y)

##Set the scroll factor from the sprite.[br]
##This makes the object have a depth effect, [u]the lower the value, the greater the depth[/u].
static func setScrollFactor(object: Variant, x: float = 1, y: float = 1) -> void: FunkinSpritesServer.setScrollFactor(object,x,y)

static func setObjectOrder(object: Variant, order: int)  -> void: FunkinSpritesServer.setObjectOrder(object,order) ##Set the order of the object in the screen.

static func getObjectOrder(object: Variant) -> int: return FunkinSpritesServer.getObjectOrder(object) ##Returns the object's order.

##Returns if the sprite, created using [method makeSprite] or [method makeAnimatedSprite] or [method setVar], exists.
static func spriteExists(tag: StringName) -> bool: 
	return FunkinSpritesServer.spritesCreated.has(tag) or modVars.get(tag) is Node

static func getMidpoint(object: Variant) -> Vector2: ##Returns the 2d midpoint of the object.
	return FunkinSpritesServer.get_midpoint(object)

static func getMidpoint3D(object: Variant) -> Vector3: ##Returns the 3d midpoint of the object..
	return FunkinSpritesServer.get_midpoint_3d(object)
#endregion


#region Animation Methods
##Add Animation Frames for the [param object], useful if you are creating custom [Icon]s.
static func addAnimation(object: Variant, animName: StringName, frames: Array = [], frameRate: float = 24, loop: bool = false) -> AnimationData:
	return FunkinAnimationServer.add_animation(object, animName, frames, frameRate, loop)
	
##Add animation to a [Sprite] using the prefix of his image.
static func addAnimationByPrefix(object: Variant, animName: StringName, xmlAnim: StringName, frameRate: float = 24, loop: bool = false, indices: Variant = null) -> AnimationData:
	return FunkinAnimationServer.add_animation_by_prefix(object, animName, xmlAnim, frameRate, loop, indices)

##Makes the [param object] play a animation, if exists. If [param force] and the current anim as the same name, that anim will be restarted.
static func playAnim(object: Variant, anim: StringName, force: bool = false, reverse: bool = false) -> void:
	FunkinAnimationServer.play_anim(object, anim, force, reverse)

##Add offset for the animation of the sprite.
static func addAnimationOffset(object: Variant, anim: StringName, offsetX: float, offsetY: float)  -> void: FunkinAnimationServer.add_offset(object, anim, offsetX, offsetY)

#endregion


#region Text Methods
##Creates a Text
static func makeText(tag: StringName,text: Variant = '', width: float = 500, x: float = 0, y:float = 0) -> Label: return FunkinTextServer.makeText(tag, text, width, x, y)
static func setTextString(tag: Variant, text: Variant = '') -> void: FunkinTextServer.setTextString(tag, text) ##Set the text string
static func setTextColor(text: Variant, color: Variant) -> void: FunkinTextServer.set_text_color(text, color) ##Set the color from the text
static func setTextBorder(text: Variant, border: float, color: Color = Color.BLACK) -> void: FunkinTextServer.setTextBorder(text, border, color) ##Set Text Border

##Set the Font of the Text
static func setTextFont(text: Variant, font: Variant = 'vcr.ttf') -> void: FunkinTextServer.set_text_font(text, font)
static func getTextFont(text: Variant) -> FontFile: return FunkinTextServer.get_text_font(text)

static func _find_font(font: Variant) -> Font: return font if font is Font else Paths.font(font)

##Set the Text Alignment
static func setTextAlignment(tag: Variant, alignmentHorizontal: StringName = &'left', alignmentVertical: StringName = &'') -> void:
	FunkinTextServer.setTextAlignment(tag, alignmentHorizontal, alignmentVertical)

##Set the font's size of the Text
static func setTextSize(text: Variant, size: float = 15) -> void: FunkinTextServer.set_text_size(text, size)

##Add Text to game
static func addText(text: Variant, front: bool = false, camera: StringName = &"hud") -> void: FunkinTextServer.addText(text, front, camera)

##Remove Text from the game, if [code]delete[/code] is [code]true[/code], the text will be removed from the memory.
static func removeText(text: Variant,delete: bool = false) -> void: FunkinTextServer.removeText(text, delete)

static func textsExits(tag: String) -> bool: return FunkinTextServer.textsCreated.has(tag) ##Check if the Text as created
#endregion


#region Tween Methods
##Start Tween. Similar to [method TweenService.create_tween].[br]
##[b]OBS:[/b] if [param time] is [code]0.0[/code], this will cause the function to set the values, without any tween.
static func doTween(tag: StringName, object: Variant, what: Dictionary,time: Variant = 1.0, easing: StringName = &'') -> FunkinTweenerObject:
	return FunkinTweenerServer.create_tween_safe(object, what, time, easing, tag)

##Create a Tween Method, similar to [Tween.tween_method]
static func doTweenMethod(tag: StringName, from: Variant, to: Variant, time: Variant, ease: String, method: Callable) -> FunkinTweenerMethod:
	return FunkinTweenerServer.create_tween_method(from, to, time, ease, method, tag)


##Do Tween for a [ShaderMaterial].[br][br]
##[code]shader[/code] can be a [ShaderMaterial] or a tag([String]) used in [method initShader].
##Example of Code:[codeblock]
##var shader_material: ShaderMaterial = Paths.loadShader('ChromaticAbberration')
##setShaderFloat(shader_material,'strength',0.005)
##doShaderTween(shader_material,'strength',0.0,0.2,&'','chrom_tag')
##
##initShader('ChromaticAbberation','chrom')
##setShaderFloat('chrom','strength',0.01)
##doShaderTween('chrom','strength',0.0,0.2,&'','chrom_tag')[/codeblock]
static func doShaderTween(shader: Variant, parameter: StringName, value: Variant, time: float, ease: StringName = &'', tag: StringName = '') -> FunkinTweenerMethod:
	return FunkinTweenerServer.create_tween_shader(shader, parameter, value, time, ease, tag)

static func doShadersTween(shaders: Array, parameter: StringName, value: Variant, time: float, ease: StringName = &'') -> Array[FunkinTweenerMethod]:
	var tweens: Array[FunkinTweenerMethod]; for i in shaders: tweens.append(doShaderTween(i,parameter,value,time,ease))
	return tweens

static func cancelTween(tag: String) -> void: FunkinTweenerServer.cancel_tween(tag) ##Cancel the Tween. See also [method startTween].
static func isTweenRunning(tag: String) -> bool: return FunkinTweenerServer.is_tween_running(tag) ##Detect if the a Tween is running by its tag.

##Creates a TweenZoom for cameras.
static func doTweenZoom(tag: StringName,object: Variant, toZoom, time = 1.0, easing: StringName = &'') -> FunkinTweenerObject: 
	return doTween(tag, object, {&'zoom': float(toZoom)}, float(time), easing)

##Create a Tween changing the x value, can be usefull not just for positions, but for anothers variables too, the same for the different tweens.
##Example: [codeblock]
##doTweenX('tween','boyfriend',2) #Make a tween of the boyfriend position.
##doTweenX('tween','boyfriend.offset',2) #Make a tween of the boyfriend offset.
##[/codeblock]
##See also [method doTweenY] and [method doTweenAngle].
static func doTweenX(tag: StringName,object: Variant, to: Variant, time: float = 1.0, easing: StringName = &'') -> FunkinTweenerObject: 
	return doTween(tag, object,{&'x': float(to)},float(time),easing)

##Creates a Tween for the y value. See also [method doTweenX] and [method doTweenAngle].
static func doTweenY(tag: StringName,object: Variant, to: Variant, time = 1.0, easing: StringName = &'') -> FunkinTweenerObject: 
	return doTween(tag, object,{&'y': float(to)},float(time),easing)

##Creates a Tween for the alpha of a [Node]. See also [method doTweenColor].
static func doTweenAlpha(tag: StringName, object: Variant, to: Variant, time: Variant = 1.0, easing: StringName = &'') -> FunkinTweenerObject: 
	return doTween(tag, object,{^"modulate:a": float(to)},float(time),easing)
	
##Creates a Tween for the color of a [Node]. See also [method doTweenAlpha].
static func doTweenColor(tag: StringName, object: Variant,color: Variant, time = 1.0, easing: StringName = &'') -> FunkinTweenerMethod:
	object = FunkinProperty._find_object(object); if !object: return null
	return doTweenMethod(tag, object.modulate,_get_color(color), float(time), easing,_modulate_method.bind(object))

static func _modulate_method(col: Variant, obj: CanvasItem) -> void: obj.modulate = Color(col.r,col.b,col.g,obj.modulate.a)

##Creates a Tween for the rotation of a [Node]. See also [method doTweenX] and [method doTweenY].
static func doTweenAngle(tag: StringName, object: Variant, to: Variant, time = 1.0, easing: StringName = &'') -> FunkinTweenerObject: 
	object = FunkinProperty._find_object(object)
	if !object: return
	if object is Node3D: return doTween(object,{^'rotation_degrees:z': float(to)},time,easing, tag)
	return doTween(tag, object,{&'angle': float(to)}, time, easing)
#endregion


#region Note Tween Methods
static func doNoteTween(tag: StringName, id: int, properties: Dictionary, time: float = 1.0, easing: StringName = &"") -> FunkinTweenerObject:
	return doTween(
		tag,
		FunkinProperty.get_property("strumLineNotes.members[%d]" % int(id)),
		properties,
		float(time),
		easing
	)

##Creates a Tween for the rotation of a Note. See also [method noteTweenY] and [method noteTweenAngle].
static func noteTweenX(tag: StringName, id: Variant,target = 0.0,time = 1.0,easing: StringName = &'') -> FunkinTweenerObject: 
	return doNoteTween(tag, id,{^'position:x': float(target)},float(time),easing)

##Creates a Tween for the rotation of a Note. See also [method noteTweenX] and [method noteTweenAngle].
static func noteTweenY(tag: StringName, id: Variant,target: Variant  = 0.0,time = 1.0,easing: StringName = &'') -> FunkinTweenerObject: 
	return doNoteTween(tag, id,{^'position:y': float(target)},float(time),easing)

##Creates a Tween for the rotation of a Note. See also [method noteTweenColor].
static func noteTweenAlpha(tag: StringName,id: Variant,target: Variant = 0.0, time = 1.0, easing: StringName = &'') -> FunkinTweenerObject: 
	return doNoteTween(tag, id,{^'modulate:a': float(target)},float(time),easing)

##Creates a Tween for the rotation of a Note. See also [method noteTweenY] and [method noteTweenAngle].
static func noteTweenAngle(tag: StringName, id: Variant,target = 0.0,time = 1.0,easing: StringName = &'') -> FunkinTweenerObject: 
	return doNoteTween(tag, id,{&"rotation_degrees": float(target)},float(time),easing)

##Creates a Tween for the rotation of a Note. See also [method noteTweenY] and [method noteTweenAngle].
static func noteTweenDirection(tag: StringName, id: Variant,target: Variant = 0.0, time: Variant = 1.0, easing: StringName = &'') -> FunkinTweenerObject: 
	return doNoteTween(tag,id,{&"direction": float(target)},float(time),easing)

##Creates a Tween for the color of a Note. See also [method noteTweenAlpha].
static func noteTweenColor(tag: StringName, id: Variant,color: Variant = 0.0,time: Variant = 1.0,easing: StringName = &'') -> FunkinTweenerMethod: 
	id = FunkinProperty.get_property("strumLineNotes.members[%d]" % int(id)); if !id: return
	color = _get_color(color)
	return doTweenMethod(
		tag,
		Vector3(id.modulate.r,id.modulate.g,id.modulate.b),
		Vector3(color.r,color.g,color.b),
		float(time),
		easing,
		_modulate_method.bind(id)
	)
#endregion

#region Note Methods
static func createStrumNote(note_data: int, style: StringName = &'funkin', tag: StringName = &''): ##Returns a new Strum Note. If you want to add the Strum to a group, see also [method addSpriteToGroup].
	if !NoteStyleData._load_style(style): debug_error("Error creating Strum Note: '"+style+"' style don't exists!"); return
	var strum: StrumNote = StrumNote.new(note_data)
	strum.loadFromStyle(style)
	if tag: modVars[tag] = strum
	return strum
#endregion

#region Shader Methods
##Create Shader using tags, making it possible to create several shaders from the same material;[codeblock]
##initShader('shader1','Chrom');
##initShader('shader2','Chrom');##[/codeblock]
##[b]OBS:[/b] if [code]obrigatory[/code] is set to [code]true[/code], the shader will be created even [code]shadersEnabled[/code] is false.
static func initShader(shader: String, tag: StringName = &'', obrigatory: bool = false) -> ShaderMaterial: return FunkinShadersServer.init(shader,tag,obrigatory)

##Add [Material] to a [code]camera[/code], [code]shader[/code] can be a [String] or a [Array].[br][br]
##[b]OBS:[/b] If the [code]shader[/code] was not started using [method initShader], this function will call automatically.
##[br][br]Example of code:[codeblock]
##var shader_material1 = ShaderMaterial.new()
##var shader_material2 = ShaderMaterial.new()
##addShaderToCamera('game',shader_material1)
##addShaderToCamera('game', shader_material1, shader_material2)
###or
##addShaderToCamera('game','ChromaticAberration',shader_material2)
##[/codeblock][br]
##If you want to add the same shader in more cams:
##[codeblock]
##addShaderToCamera(['game','hud'],shader_material2)
##[/codeblock]
##[b]Note:[/b] The same works for [method removeShaderCamera].
##[br][br]See also [method setSpriteShader].
static func addShadersToCamera(camera: Variant, ...shaders: Array) -> void: FunkinShadersServer.add_shaders_to_camera(camera,shaders)

static func setBlendMode(object: Variant, blend: String) -> void: FunkinShadersServer.setBlendMode(object, blend) ##Sets Object Blend mode, can be: [code]add,subtract,mix[/code]

static func addShaderFloat(shader: Variant, parameter: String, value: float): FunkinShadersServer.addShaderFloat(shader, parameter, value) ##Add [code]value[/code] to a [u][float] parameter[/u] of a [code]shader[/code] created using [method initShader].
static func setShaderParameter(shader: Variant, parameter: String, value: Variant): FunkinShadersServer.setShaderParameter(shader, parameter, value)
static func getShaderParameter(shader: Variant, shaderVar: String) -> Variant: return FunkinShadersServer.getShaderParameter(shader, shaderVar)
static func removeShaderCamera(camera: Variant, shader: Variant) -> void: FunkinShadersServer.remove_camera_shader(camera, shader) ##Remove shader from the camera, [code]shader[/code] can be a [String] or a [Array].[br]See also [method addShaderCamera].
#endregion


#region Camera Methods
static func createCamera(tag: String, order: int = 5) -> FunkinCamera2D: return FunkinCameraServer.createCamera(tag, order)
static func cameraFlash(cam: Variant, flashColor: Variant = Color.WHITE, time: Variant = 1.0) -> void: ##Do Camera Flash
	FunkinCameraServer.camera_flash(FunkinCameraServer.camera_get(cam), flashColor, float(time))
static func cameraShake(cam: Variant, intensity: float = 0.0, time: float = 1.0) -> CameraShake: 
	return FunkinCameraServer.camera_shake(FunkinCameraServer.camera_get_controller(cam), intensity, time) ##Make a camera shake.
static func cameraFade(cam: Variant, color: Variant = Color.BLACK, time: Variant = 1.0, fadeIn: bool = true): 
	FunkinCameraServer.camera_fade(FunkinCameraServer.camera_get(cam), color, time, fadeIn) ##Make a fade in, or out, in the camera.
static func cameraSetTarget(target: StringName = 'boyfriend') -> void: game.moveCamera(target) ##Move the game camera for the [code]target[/code].
static func setObjectCamera(object: Variant, camera: Variant): FunkinSpritesServer.set_object_camera(object, camera)##Set the object camera.
static func cameraAsString(string: StringName) -> StringName: return FunkinCameraServer.camera_get_name(string)##Detect the camera name using a String.
#endregion

#region Position Methods
static func getCenterBetween(object1: Variant, object2: Variant) -> Vector2:
	object1 = FunkinProperty._find_object(object1); if !object1: return Vector2.ZERO
	object2 = FunkinProperty._find_object(object2); if !object2: return Vector2.ZERO
	return _get_center_between(object1.position, object2.position)

static func getCenterBetween3D(object1: Variant, object2: Variant) -> Vector3:
	object1 = FunkinProperty._find_object(object1); if !object1: return Vector3.ZERO
	object2 = FunkinProperty._find_object(object2); if !object2: return Vector3.ZERO
	return _get_center_between(object1.position, object2.position)

static func _get_center_between(pos_1: Variant, pos_2: Variant) -> Variant: return pos_1 + (pos_2 - pos_1) * 0.5

static func getCharStagePos(char: StringName): return game.get_char_stage_position(char)

static func getFocusPosition(char: Variant) -> Variant: ##Returns the camera position from [param char].
	if char is String: char =  FunkinProperty._find_object(char)
	if !char: return Vector2.ZERO
	if game: return game.get_focus_position(char)
	if char is String: char = getProperty(char)
	if char is Character2D: return char.getCameraPosition()
	if char is FunkinSprite2D: return char.getMidpoint()
	return char.position

static func getFocusPosition3D(char: Variant) -> Vector3: ##Returns the camera position from [param char].
	if char is String: char =  FunkinProperty._find_object(char)
	if !char: return Vector3.ZERO
	if game: return game.get_focus_position(char)
	if char is String: char = getProperty(char)
	if char is CharacterSprite3D: return char.getCameraPosition()
	return char.position
#endregion

#region Game Methods
static func startCountdown() -> void: callScript(&"scripts/Countdown",&"start_count_down") ##Starts the song count down.
static func restartSong(transition: bool = true): if game: game.reloadPlayState(transition) ##Restarts the game song.
static func endSong(skip_transition: bool = false) -> void: if game: game.endSound(skip_transition) ##Ends the game song.
static func exitSong(skip_transition: bool = false): if game: game.exit(skip_transition) 
static func setHealth(value: float) -> void: if game: game.health = value ##Sets the player health.
static func getHealth() -> float: return game.health if game else 0.0 ##Returns the player health.
static func detectSection() -> StringName: return game.detectSection() if game else &"boyfriend" ##Returns the current character section name of the song.
static func startVideo(path: Variant, isCutscene: bool = true) -> VideoStreamPlayer: return game.startVideo(path, isCutscene) if game else null ##Starts a video.
#endregion


#region Sound Methods
##Skip the song to [code]time[/code].[br]
##If [code]kill_notes[/code], the notes before that time will be destroyed, avoiding missing them and ending up dying.

static func setSongPosition(time: Variant, kill_previous_notes: bool = false): game.seek_to(float(time), kill_previous_notes)
static func setSoundPosition(sound: Variant, position: float) -> void: FunkinAudioServer.setSoundPosition(sound, position) ##Set the [param sound] position in seconds.
static func setSoundVolume(sound: Variant, volume: float = 1) -> void: FunkinAudioServer.setSoundVolume(sound, volume)
static func getSoundTime(sound: Variant) -> float: return FunkinAudioServer.getSoundTime(sound) ##Get the Sound Length.
static func getSongPosition() -> float: return Conductor.songPositionDelayed ##Get Song Position.

##Play a sound. [code]path[/code] can be a [String] or a [AudioStream].
##[br]Example of code: [codeblock]
##playSound('noise',1.0,'noise_sound')
##
##var audio = Paths.sound('noise2')
##playSound(audio,1.0)
##[/codeblock]
static func playSound(path: Variant, volume: float = 1.0, tag: String = "", force: bool = false, loop: bool = false) -> AudioStreamPlayer:
	return FunkinAudioServer.playSound(path, volume, tag, force, loop)
#endregion

#region Keyboard Methods
static func keyboardJustPressed(key: String) -> bool: return InputUtils.isKeyJustPressed(OS.find_keycode_from_string(key)) ##Detect if the keycode is just pressed. See also [method keyboardJustReleased].
static func keyboardJustReleased(key: String) -> bool: return InputUtils.isKeyJustReleased(OS.find_keycode_from_string(key)) ##Detect if the keycode is just pressed. See also [method keyboardJustPressed].
#endregion


#region Script Methods
##Detect if a script[u], created using [method addScript], [/u] is running.
static func scriptIsRunning(path: StringName) -> bool: return _script_path(path) in scriptsCreated

static func callMethod(object: Variant, function: String, ...variables: Array) -> Variant:
	object = FunkinProperty._find_object(object); if !(object and object.has_method(function)): return
	return object.callv(function,variables)

##Returning a new [Object] with the script created, useful if you want to call a function without using [method callScript] or want to change a variable of the script.
##Example of code:[codeblock]
##var script = addScript('scenes/effects/particles/Particles')
##script.lifetime = 1.0
##[/codeblock]
static func addScript(path: String, tag: StringName = &'') -> Object:
	path = _script_path(path); if !tag: tag = StringName(path)
	var script = scriptsCreated.get(tag); if script: return script
	script = _load_script_from_path(path); if !script: return
	registerScript(script,tag)
	return script


##Returns the script added using [method addScript].
static func getScript(path: String): return scriptsCreated.get(path)

static func registerCallback(script: Object, function: StringName) -> void: 
	if !script: return
	var args = script.get_meta(&"arguments")
	if !args: debug_error("Error on Register Callback: Script don't have methods registred."); return
	if !function in args: debug_error("Error on Register Callback: Script don't have "+function+" method.");return
	
	var list = method_list.get(function)
	if list and script in list:  
		debug_error("Error on Register Callback: Callback already registred in this script.");
		return
	_register_callback_no_check(script,function)

##Disables callbacks, useful if you no longer need to use them. Example:
##[codeblock]
##disableCallback(self,'onUpdate') #This disable the game to call "onUpdate" in this script
##[/codeblock]
static func unregisterCallback(script: Variant, function: StringName):
	if !script: return
	var func_scripts = method_list.get(function); if !func_scripts: return
	func_scripts.erase(_get_script(script))

##Creates a new script from [param path].
static func loadScript(path: String) -> GDScript: 
	path = PathsStore.detectFileFolder(_script_path(path))
	return _load_script_code(path) if path else null

##Calls a function in the script, returning a [Variant] that the function returns.
static func callScript(script: Variant, function: StringName, ...parameters: Array) -> Variant:
	return _callv_script(_get_script(script), function ,parameters)

static func _callv_script(script: Variant, function: StringName, parameters: Array):
	if !script: return
	var args = script.get_meta(&"arguments"); if !args: return
	if !args.has(function): return
	args = args[function] 
	if !args: return script.call(function)
	
	parameters = _sign_parameters(args, parameters)
	return script.callv(function, parameters) 

##Calls a function for every script created.
static func callOnScripts(function: StringName, ...parameters: Array) -> void:
	var scripts = method_list.get(function); if !scripts: return
	var i = scripts.size()
	while i: i -=1; _callv_script(scripts[i],function, parameters)

static func _sign_parameters(args: Array, parameters: Array) -> Array:
	var i: int = 0
	var params: Array
	var args_size = args.size()
	var length = mini(args_size,parameters.size())
	
	while i < length: 
		params.append(_sign_value(parameters[i],args[i].type)); 
		i += 1;
	
	_insert_default_args_to_params(params,args,i)
	return params

static func _insert_default_args_to_params(parameters: Array, args: Array, from: int = 0):
	while from < args.size(): 
		var i = args[from]
		if i.has(&'default'): break
		parameters.append(MathUtils.get_new_value(i.type));
		from += 1

static func _sign_value(value: Variant, type_to_convert: Variant.Type) -> Variant:
	return value if type_to_convert == TYPE_NIL else type_convert(value,type_to_convert)

##Calls a function for every script created.[br]
##returns a [Array] with the values returned from each call.
static func callOnScriptsWithReturn(function: StringName, ...parameters: Array) -> Array:
	var returns: Array
	var func_args = method_list.get(function); if !func_args: return returns
	var i = func_args.size()
	while i: i -=1; returns.append(_callv_script(func_args[i],function,parameters))
	return returns


func close() -> void: removeScript(self); ##Close this script.
#endregion


#region Event Methods
##Trigger Event from arguments. 
##This method will convert the [param args] to a Dictionary with value that match the event.
##[codeblock]
##triggerEvent('Change Character', 'gf', 'gf-dead') 
###Converts the arguments to {"char": "gf", "json": "gf-dead"}
##
##triggerEvent('Add Camera Zoom', '0.015', '0.03')
###Converts the arguments to {"game_zoom": 0.015, "hud_zoom": 0.03}
##[/codeblock] See also [method triggerEventData].
static func triggerEvent(event: StringName,...args: Array) -> void:
	game.trigger_event(event, EventNote.get_values_from_array(event,args))

##Trigger Event using a [Dictionary].[codeblock]
##triggerEventData('Change Character',{"char": "bf", "json": "bf-dead"})
##triggerEventData('Add Camera Zoom',{"game_zoom": 0.015, "hud_zoom": 0.03})
##[/codeblock]See also [method triggerEvent].
static func triggerEventData(event: StringName, values: Dictionary) -> void: 
	EventNote.fix_variables(event, values)
	game.trigger_event(event,values)
#endregion

#region Color Methods
##Returns a [Color] using a [Array][[color=red]r[/color], [color=green]g[/color], [color=blue]b[/color]]:
##Example:[codeblock]
##getColorFromArray([255,255,255], true)# Returns Color.WHITE (Color(1,1,1))
##getColorFromArray([1,1,1], false) #Also returns Color.WHITE (Color(1,1,1))
##getColorFromArray([255,0,0])# Returns Color(1,0,0)
##[/codeblock]
static func getColorFromArray(array: Array, divided_by_255: bool = true) -> Color:
	return Color(array[0]/255.0,array[1]/255.0,array[2]/255.0) if divided_by_255 else Color(array[0],array[1],array[2])

##Returns a [Color] using his name:
##[codeblock]
##getColorFromName('BLACK') #Returns Color.BLACK (Color(0,0,0))
##[/codeblock]
static func getColorFromName(color_name: String, default: Color = Color.WHITE) -> Color: return Color.from_string(color_name.to_lower(),default)
#endregion

#region Utils
static func getArrayIndex(array: Variant, index: int, default: Variant) -> Variant:
	if index >= 0 and index < array.size(): return array[index]
	return default

static func debugPrint(string: Variant, color: Color = Color.WHITE): debug_message(str(string),color,false)
#endregion

static func reset(absolute: bool = false):
	inCutscene = false
	inGameOver = false
	if absolute: seenCutscene = false
 
