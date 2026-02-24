@tool
class_name ScreenUtils

static var screenWidth: float:
	get(): return screenSize.x
static var screenHeight: float:
	get(): return screenSize.y

static var screenSize: Vector2

static var screenCenter: Vector2

static var screenOffset: Vector2

static var defaultSize: Vector2
static var defaultSizeCenter: Vector2
static var defaultAspect: Window.ContentScaleAspect = getScreenAspectViaString(
	ProjectSettings.get_setting("display/window/stretch/aspect")
)

static var defaultScaleMode: Window.ContentScaleMode = getScreenScaleModeViaString(
	ProjectSettings.get_setting("display/window/stretch/scale_mode")
)
static var main_window: Window

static func _static_init() -> void:
	if !Engine.is_editor_hint(): _set_window.call_deferred()
	defaultSize.x = ProjectSettings.get_setting('display/window/size/viewport_width')
	defaultSize.y = ProjectSettings.get_setting('display/window/size/viewport_height')
	screenSize = defaultSize
	defaultSizeCenter = defaultSize*0.5
	updateScreenData()

static func _set_window():
	main_window = Engine.get_main_loop().root.get_window()
	main_window.size_changed.connect(_update_screen_size)
	_update_screen_size()
	
static func updateScreenData():
	screenSize = defaultSize - screenOffset
	screenCenter = screenSize * 0.5
	
static func _update_screen_size() -> void:
	var aspect = main_window.content_scale_aspect
	match main_window.content_scale_mode:
		Window.CONTENT_SCALE_MODE_DISABLED: aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		#_: return
	var new_size = main_window.size
	var offset: Vector2 = Vector2.ONE
	var div = Vector2(new_size)/defaultSize
	
	match aspect:
		Window.CONTENT_SCALE_ASPECT_EXPAND: offset = Vector2(new_size)/defaultSize
		Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH: offset.y = maxf(1.0,div.y / div.x)
		Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT: offset.x = maxf(1.0,div.x / div.y)
		Window.CONTENT_SCALE_ASPECT_IGNORE: pass
		_: offset = Vector2(main_window.content_scale_size)/defaultSize
	screenOffset = defaultSize * (Vector2.ONE - offset)
	updateScreenData()

static func getScreenAspectViaString(aspect: StringName) -> Window.ContentScaleAspect:
	match aspect:
		&'keep': return Window.CONTENT_SCALE_ASPECT_KEEP
		&'keep_width': return Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH
		&'keep_height': return Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT
		&'expand': return Window.CONTENT_SCALE_ASPECT_EXPAND
		_: return Window.CONTENT_SCALE_ASPECT_IGNORE

static func getScreenScaleModeViaString(scale_mode:String) -> Window.ContentScaleMode:
	match scale_mode:
		&'canvas_items': return Window.ContentScaleMode.CONTENT_SCALE_MODE_CANVAS_ITEMS
		&'viewport': return Window.ContentScaleMode.CONTENT_SCALE_MODE_VIEWPORT
		_: return Window.ContentScaleMode.CONTENT_SCALE_MODE_DISABLED
