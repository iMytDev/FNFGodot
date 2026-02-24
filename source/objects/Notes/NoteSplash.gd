
@icon("res://icons/splash.png")
class_name NoteSplash extends FunkinAnimatedSprite2D

const HOLD_ANIMATIONS: Array = [&'start',&'hold',&'end']
static var mosaicShader: Material

var texture: StringName ## Splash Texture

var direction: int ##Splash Direction
var isPixelSplash: bool: set = _set_pixel ##If is a [u]pixel[/u] splash.

@warning_ignore("unused_private_class_variable")
var _is_custom_parent: bool #Used in StrumState.

var strum: Node ##The Splash strum.

var holdSplash: bool

var splashName: StringName
var splashStyle: StringName
var splashPrefix: StringName
var splashData: Dictionary

func _init(): 
	super()
	animation.animation_finished.connect(_on_animation_finished)
	visibility_changed.connect(_on_visibility_changed)

func _ready() -> void: super(); if holdSplash: _update_animation_scale()
func _on_visibility_changed(): process_mode = PROCESS_MODE_INHERIT if visible else PROCESS_MODE_DISABLED; 

func show_splash() -> void:
	if holdSplash: animation.play(&'start',false); _update_animation_scale();
	else: animation.play_random()
	visible = true

func _update_animation_scale() -> void: 
	var data = animation.animationsArray.get(&"hold"); 
	if data: data.speed_scale = minf(1.0 / (Conductor.bpm_data.stepCrochetMs*8.0),3.0)

func _set_pixel(isPixel: bool):
	if isPixel == isPixelSplash: return
	isPixelSplash = isPixel
	
	if isPixel:
		if splashData.get(&'isPixel'): return
		if !mosaicShader: mosaicShader = Paths.loadShader('MosaicShader')
		image.material = mosaicShader
		image.material.set_shader_parameter(&'strength',6.0)
	else: image.material = null


func _on_animation_finished(anim_name: StringName) -> void:
	if !holdSplash: visible = false; return  
	match anim_name:
		&'start': animation.play(&'hold',true)
		&'end': visible = false

func _process(_d) -> void:
	super(_d)
	if !(visible and holdSplash and strum): return
	followStrum()

func followStrum() -> void:
	if !strum: return
	modulate.a = strum.modulate.a
	position = strum.position

##Add animation to splash. Returns [code]true[/code] if the animation as added successfully.
static func loadSplash(style: StringName, splash_name: StringName = &'default', prefix: StringName = &'', holdSplash: bool =false) -> NoteSplash:
	var data = NoteStyleData.getStyleData(style,splash_name,NoteStyleData.StyleType.SPLASH)
	if !data: return
	var splash: NoteSplash = NoteSplash.new()
	splash.splashData = data
	splash.splashStyle = style
	splash.splashName = splash_name
	splash.splashPrefix = prefix
	splash.holdSplash = holdSplash
	if !_load_splash_animation(splash,prefix): return null
	return splash

static func loadSplashFromNote(note: Note) -> NoteSplash: 
	return loadSplash(note.splashStyle,note.splashName,note.splashPrefix,note.isSustainNote)

static func _load_splash_animation(splash: NoteSplash,prefix: StringName) -> bool:
	var data = splash.splashData.data.get(prefix)
	if !data: data = splash.splashData.data.get(&'default'); if !data: return false
	if data is Array: data = data.pick_random()
	
	var asset = data.get(&'assetPath')
	if !asset: asset = splash.splashData.assetPath; if !asset: return false
	
	asset = Paths.texture(asset)
	if !asset: return false
	splash.image.texture = asset
	
	var offsets = splash.splashData.get(&'offsets',Vector2.ZERO)
	var scale = data.get(&'scale',splash.splashData.get(&'scale',1.0))
	
	if !splash.holdSplash:
		var prefix_anim = data.get(&'prefix'); if !prefix_anim: return false
		splash.animation.add_animation_by_prefix(&'splash',prefix_anim,24.0,false)
		splash.offset = data.get(&'offsets',offsets)
		splash.scale = Vector2(scale,scale)
		return true

	for i in HOLD_ANIMATIONS:
		var hold_data = data.get(i); if !data: continue
		var sprefix = hold_data.get(&'prefix'); if !sprefix: continue
		
		var is_hold: bool = i==&'hold'
		splash.animation.add_animation_by_prefix(i,sprefix,24.0, is_hold)
		splash.animation.add_animation_offset(i, data.get(&'offsets',offsets))
		splash.animation.auto_loop = true
	return true
