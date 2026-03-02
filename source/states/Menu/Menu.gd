extends Node

const ModeSelect = preload("uid://dbcawd2so03ht")

var introText: PackedStringArray = [
	'A Engine made on \n#Godot',
	'Total Credits to \nFNF Team',
	'Special Thanks for \nShadow Mario'
]

var curIntroText: int
var introTime: float

var alphaText: FunkinText = FunkinText.new()

var flash: SolidNode2D = SolidNode2D.new()
var flashTween: Tween

var gfBeating: FunkinAnimatedSprite2D = FunkinAnimatedSprite2D.new('gfDanceTitle')
var logoBomping: FunkinAnimatedSprite2D = FunkinAnimatedSprite2D.new('logoBumpin')
var pressStart: FunkinAnimatedSprite2D = FunkinAnimatedSprite2D.new('titleEnter')

var bpm: float = 120.0
var beat: int: set = set_beat
var menuState: int
var playIntroText: bool = true

var soundMenu: AudioStreamPlayer
func _ready():
	DiscordRPC.details = 'In Menu'
	DiscordRPC.refresh()
	
	var bpm_data = Paths.loadJson('images/gfDanceTitle')
	
	soundMenu = FunkinGD.playSound(Paths.music('freakyMenu'),1,'freakyMenu',false,true)
	flash.scale = Vector2(ScreenUtils.screenWidth,ScreenUtils.screenHeight)
	flash.modulate.a = 0
	
	alphaText.position = ScreenUtils.screenCenter
	alphaText.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alphaText.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(alphaText)
	
	add_child(gfBeating)
	
	add_child(pressStart)
	add_child(logoBomping)
	add_child(flash)
	logoBomping.animation.add_animation_by_prefix('logo','logo bumpin')
	logoBomping.visible = false
	logoBomping.position = Vector2(bpm_data.get('titlex',-150),bpm_data.get('titley',-100))
	logoBomping.name = &'logoBomping'
	
	gfBeating.image.texture = Paths.texture('gfDanceTitle')
	gfBeating.animation.add_animation_by_prefix('danceLeft','gfDance',24,false,range(15))
	gfBeating.animation.add_animation_by_prefix('danceRight','gfDance',24,false,range(15,30))
	gfBeating.visible = false
	
	gfBeating.position = Vector2(bpm_data.get('gfx',600),bpm_data.get('gfy',40))
	gfBeating.name = &'GfBeating'
	bpm = bpm_data.get('bpm',102)
	
	pressStart.image.texture = Paths.texture('titleEnter')
	pressStart.animation.add_animation_by_prefix('idle','ENTER IDLE',24,true)
	pressStart.animation.add_animation_by_prefix('pressed','ENTER PRESSED',24,true)
	pressStart.visible = false
	pressStart.position = Vector2(bpm_data.get('startx',100),bpm_data.get('starty',ScreenUtils.screenHeight - 150))
	pressStart.name = &'pressStart'
	
	SceneManager.on_scene_changed.connect(queue_free,CONNECT_ONE_SHOT)
	if not playIntroText: changeState(1)
	
func changeState(state: int = 0):
	if state == 1:
		alphaText.queue_free()
		logoBomping.visible = true
		gfBeating.visible = true
		pressStart.visible = true
		doFlash()
	menuState = state
	
func set_beat(newBeat: int):
	if beat == newBeat: return
	beat = newBeat
	gfBeating.animation.play(&'danceRight' if newBeat % 2 == 1 else &'danceLeft')
	logoBomping.animation.play(&'logo',true)
	
func _process(delta: float) -> void:
	if soundMenu: beat = int(soundMenu.get_playback_position() / (60.0/bpm))
	introTime += delta
	match menuState:
		0:
			if introTime < 1: return
			curIntroText = int(introTime)
			if curIntroText >= introText.size(): 
				changeState(1)
			else:
				var text = introText[curIntroText]
				
				if introTime - curIntroText < 0.5: 
					alphaText.text = text.substr(0,text.find('\n'))
				else: alphaText.text = text

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == 1 or event is InputEventKey and event.keycode == KEY_ENTER)\
	 and event.pressed:
		match menuState:
			0: changeState(1)
			1:
				pressStart.animation.play(&'pressed')
				doFlash()
				FunkinGD.playSound(Paths.sound('confirmMenu'))
				get_tree().create_timer(1.5).timeout.connect(SceneManager.change_scene.bind(ModeSelect.new()))
				menuState = 2
func doFlash():
	if flashTween: flashTween.kill()
	flash.modulate.a = 1
	flashTween = create_tween()
	flashTween.tween_property(flash,'modulate:a',0,2.0)
