@abstract
##PlayState Base.
extends "res://source/states/StrumState.gd"

const PauseSubstate = preload("uid://yw07oc1elhfb")

const Bar = preload("uid://cesg7bsxvgdcm")
const Stage = preload("uid://dh7syegxufdht")

const CharacterEditor = preload("uid://droixhbemd0xd")
const ChartEditorScene = preload("uid://eonsf5cks44n")

static var back_state = preload("uid://dbcawd2so03ht")

#region Camera Properties
@export_group('Camera')
var camHUD: FunkinCamera = FunkinCamera.new()
var camOther: FunkinCamera = FunkinCamera.new()

var cameraSpeed: float = 1.0
var zoomSpeed: float = 1.0

var isCameraOnForcedPos: bool = false
var defaultCamZoom: float = 1.0: set = set_default_zoom
#endregion

@export_group('Play Options')
var altSection: bool = false

var health: float: set = set_health

@export var singAnimations: Array = [&"singLEFT",&"singDOWN",&"singUP",&"singRIGHT"]

@export var bumpStrumBeat: float = 4.0 ##The amount of beats for the camera to give a "beat" effect.
@export var canExitSong: bool = true
@export var canPause: bool = true
@export var createPauseMenu: bool = true
@export var canGameOver: bool = true
var onPause: bool

var inGameOver: bool
var camZooming: bool ##If [code]true[/code], the camera make a beat effect every [member bumpStrumBeat] beats and the zoom will back automatically.

#region Scripts Properties
var curStage: StringName
var stageJson: Dictionary = Stage.getStageBase()
var stageDanceSprites: Array[Array]
@export_subgroup('Scripts')
@export var loadScripts: bool = true
@export var loadStageScript: bool = true
@export var loadSongScript: bool = true

@export_subgroup('Events')
@export var loadEvents: bool = true
@export var generateEvents: bool = true

static var eventNotes: Array[Dictionary]
var _event_index: int = 0
var _is_first_event_load: bool = true
#endregion


#region Gui
@export_group("Hud Elements")
@export var hideHud: bool = ClientPrefs.data.hideHud: set = _set_hide_hud

var _healthBar_State: Icon.State = Icon.State.NORMAL
var healthBar: Bar = Bar.new('healthBar')

#region Icons
const Icon := preload("res://source/objects/UI/Icon.gd")
var iconP1: Icon = Icon.new()
var iconP2: Icon = Icon.new()
var icons: Array[Icon] = [iconP1,iconP2]
var _icons_cos_sin: Vector2 = Vector2(1,0)
#endregion

#endregion


@export_group('Objects')
var pauseState: PauseSubstate

#region Game Options
@export_category('Story Mode')
var story_song_notes: Dictionary
var story_songs: PackedStringArray
var isStoryMode: bool
#endregion

@export_category("Song Data")
var songName: StringName

@export_category("Cutscene")
var seenCutscene: bool
var skipCutscene: bool = true
var inCutscene: bool
var videoPlayer: VideoStreamPlayer

var stateLoaded: bool #Used in FunkinGD
func _ready():
	Global.onSwapTree.connect(destroy,CONNECT_ONE_SHOT)
	name = 'PlayState'
	FunkinGD.game = self
	camHUD.name = &'camHUD'
	camHUD.bg.modulate.a = 0.0
	
	camOther.name = &'camOther'
	camOther.bg.modulate.a = 0.0
	add_child(camHUD)
	add_child(camOther)
	
	
	super._ready()
	health = 1.0
	
	if !isCameraOnForcedPos: moveCamera(detectSection())
	#Set Signals
	Conductor.beat_hit.connect(onBeatHit)
	Conductor.section_hit.connect(onSectionHit)
	Conductor.section_hit_once.connect(onSectionHitOnce)
	FunkinGD.callOnScripts(&'onCreatePost')
	stateLoaded = true

func _process(delta: float) -> void:
	if camZooming: camHUD.zoom = lerpf(camHUD.zoom,camHUD.defaultZoom,delta*3*zoomSpeed)
	
	FunkinGD.callOnScripts(&'onUpdate',[delta])
	
	super._process(delta)
	
	for icon in icons: updateIconPos(icon)
	
	FunkinGD.callOnScripts(&'onUpdatePost',[delta])

#region Gui
func _setup_hud() -> void:
	super._setup_hud()
	camHUD.add(uiGroup,true); 
	if hideHud: return

	healthBar.position.x = ScreenUtils.screenWidth*0.5 - healthBar.bg.width*0.5
	healthBar.position.y = ScreenUtils.screenHeight - 100.0 if not ClientPrefs.data.downscroll else 50.0
	uiGroup.add(healthBar)
	
	healthBar.draw.connect(updateIconsPivot)
	
	iconP1.name = &'iconP1'
	iconP1.scale_lerp = true
	
	iconP2.name = &'iconP2'
	iconP2.scale_lerp = true
	
	iconP1.flipX = true
	
	updateIconPos(iconP1)
	updateIconPos(iconP2)
	updateIconsPivot()
	
	uiGroup.add(iconP1)
	uiGroup.add(iconP2)
	
	healthBar.flip = true
	
	healthBar.name = &'healthBar'
	FunkinGD.callOnScripts(&"onSetupHud")


func createMobileGUI():
	super.createMobileGUI()
	var button = TextureButton.new()
	button.texture_normal = Paths.texture('mobile/pause_menu')
	button.scale = Vector2(1.2,1.2)
	button.position.x = ScreenUtils.screenCenter.x
	button.pressed.connect(pauseSong)
	add_child(button)

#region Icon Methods
func updateIconsImage(state: Icon.State = _healthBar_State):
	var player_icon = iconP1
	var opponent_icon = iconP2
	if playAsOpponent:
		player_icon = iconP2
		opponent_icon = iconP1
	match state:
		Icon.State.NORMAL:
			player_icon.animation.play(&'normal')
			opponent_icon.animation.play(&'normal')
		Icon.State.LOSING:
			if opponent_icon.hasWinningIcon: opponent_icon.animation.play(&'winning')
			else: opponent_icon.animation.play(&'normal')
			player_icon.animation.play(&'losing')
			
		Icon.State.WINNING:
			if player_icon.hasWinningIcon: player_icon.animation.play(&'winning')
			else: player_icon.animation.play(&'normal')
			opponent_icon.animation.play(&'losing')


func updateIconPos(icon: Icon) -> void:
	var icon_pos: Vector2 
	icon_pos = healthBar.get_process_position(healthBar.progress - (0.03 if icon.image.flip_h else - 0.03))
	icon.position = icon_pos + healthBar.position - icon.pivot_offset

func updateIconsPivot() -> void: for i in icons: _update_icon_pivot(i,healthBar.rotation)

func _update_icon_pivot(icon: Icon,angle: float):
	var pivot = icon.image.pivot_offset
	if !angle:
		icon.pivot_offset = Vector2(0,pivot.y) if icon.flipX else Vector2(pivot.x*2.0,pivot.y); return
	
	if icon.flipX: 
		icon.pivot_offset = Vector2(
			lerpf(pivot.x,pivot.x*2.0,_icons_cos_sin.x),
			lerpf(pivot.y,0,_icons_cos_sin.y)
		)
	else: 
		icon.pivot_offset = Vector2(
			lerpf(pivot.x,0.0,_icons_cos_sin.x),
			lerpf(pivot.y,pivot.y*2.0,_icons_cos_sin.y)
		)
#endregion

#endregion

#region Beat Methods
func iconBeat() -> void:
	if !can_process(): return #Do not beat if the game is not being processed.
	for i in icons: i.scale += i.beat_value

##Do screen beat effect. Also used in PlayState.
func screenBeat(multi: float = 1.0) -> void: camHUD.zoom += 0.03 * multi 


func onBeatHit() -> void:
	if !can_process(): return
	if camZooming and !fmod(Conductor.beat,bumpStrumBeat): screenBeat()
	iconBeat()


#endregion

#region Note Methods
func createSplash(note) -> NoteSplash:
	var splash = super.createSplash(note)
	FunkinGD.callOnScripts(&'onSplashCreate',[splash])
	return splash

func createStrum(i: int, pos: Vector2 = Vector2.ZERO) -> StrumNote:
	var strum = super.createStrum(i)
	strum.mustPress = i >= keyCount and !botplay
	strum._position = pos
	FunkinGD.callOnScripts(&'onLoadStrum',[strum])
	return strum

func spawnNote(note): super.spawnNote(note); FunkinGD.callOnScripts(&'onSpawnNote',[note])

func reloadNotes():
	var types = SONG.get('noteTypes')
	if types: for i in types: 
		FunkinGD.addScript('assets/custom_notetypes/'+i); 
		FunkinGD.addScript('custom_notetypes/'+i)
	super.reloadNotes()

func reloadNote(note: Note):
	super.reloadNote(note)
	FunkinGD.callOnScripts(&'onLoadNote',note)
	if !note.noteType: return
	var path = 'custom_notetypes/'+note.noteType+'.gd'
	FunkinGD.callScript('assets/'+path,&'onLoadThisNote',note)
	FunkinGD.callScript(path,&'onLoadThisNote',note)
func loadNotes():
	super.loadNotes()
	if !loadEvents: return
	if eventNotes: _is_first_event_load = false; return
	
	var events_to_load = SONG.get('events',[])
	var events_json = Paths.loadJson(SongData.folder+'/events.json')
	
	if events_json:
		if events_json.get('song') is Dictionary: events_json = events_json.song
		events_to_load.append_array(events_json.get('events',[]))
	eventNotes = EventNoteUtils.loadEvents(events_to_load)
	_is_first_event_load = true

func updateNote(note: Note) -> bool:
	FunkinGD.callOnScripts(&'onPreUpdateNote', note)
	var _return = super.updateNote(note)
	FunkinGD.callOnScripts(&'onUpdateNote', note)
	return _return

func updateNotes() -> void: #Function from StrumState
	super.updateNotes()
	if !generateEvents: return
	while _event_index < eventNotes.size():
		var event = eventNotes[_event_index]
		if event.t > _songPos: break
		_event_index += 1
		if event.trigger_when_opponent and playAsOpponent or event.trigger_when_player and !playAsOpponent: 
			triggerEvent(event.e,event.v)


func preHitNote(note: Note, character: Variant = null):
	if !note: return
	if !note.mustPress: camZooming = true
	
	if note.noteType:
		FunkinGD.callScript(
			'custom_notetypes/'+note.noteType+'.gd',
			&'onPreHitThisNote',
			[note,character]
		)
	
	if isPlayerNote(note): FunkinGD.callOnScripts(&'onPlayerPreHitNote',[note,character])
	FunkinGD.callOnScripts(&'goodNoteHitPre' if note.mustPress else &'opponentNoteHitPre',[note])
	FunkinGD.callOnScripts(&'onPreHitNote',[note,character])
	super.preHitNote(note)
	
func hitNote(note: Note) -> void:
	if !note: return
	if note.mustPress != playAsOpponent: health += note.hitHealth
	
	if !note.noAnimation: signCharacterFromNote(note)
	
	var audio: AudioStreamPlayer = Conductor.get_node_or_null("PlayerVoice" if note.mustPress else "OpponentVoice")
	if !audio: audio = Conductor.get_node_or_null("Voice")
	if audio: audio.volume_db = 0
	
	if note.noteType:
		FunkinGD.callScript(
			'custom_notetypes/'+note.noteType+'.gd',
			&'onHitThisNote',
			[note]
		)
	if isPlayerNote(note): FunkinGD.callOnScripts(&'onPlayerHitNote',[note])
	FunkinGD.callOnScripts(&'goodNoteHit' if note.mustPress else &'opponentNoteHit',[note])
	FunkinGD.callOnScripts(&'onHitNote',[note])
	super.hitNote(note)

@abstract func signCharacterFromNote(_note: Note) -> void
@abstract func signMissCharacterFromNote(_note: Note) -> void
@abstract func signCharacter(character, anim_name: StringName) -> void

@abstract func get_focus_position(char: Node)

func noteMiss(note, character: Variant = null) -> void:
	health -= note.missHealth
	var audio: AudioStreamPlayer = Conductor.get_node_or_null("Voice" if note.mustPress else "OpponentVoice")
	if audio: audio.volume_db = -80
	super.noteMiss(note)
	FunkinGD.callOnScripts(&'onNoteMiss',[note, character])
#endregion

#region Script Methods
func _load_song_scripts():
	if loadStageScript:
		#print('Loading Stage Script')
		FunkinGD.addScript('stages/'+curStage+'.gd')
	
	if loadSongScript and SongData.folder:
		#print('Loading Song Folder Script')
		for i in Paths.getFilesAt(SongData.folder,false,'gd'):FunkinGD.addScript(SongData.folder+'/'+i)
	
	if loadScripts:
		#print('Loading Scripts from Scripts Folder')
		for i in Paths.getFilesAt('scripts',false,'.gd'):
			FunkinGD.addScript('scripts/'+i)


func triggerEvent(event: StringName,variables: Variant) -> void:
	if !variables is Dictionary: return
	FunkinGD.callOnScripts(&'onEvent',[event,variables])
	FunkinGD.callScript('custom_events/'+event,&'onLocalEvent',[variables])
#endregion

#region Song Methods

func loadSong(data: String = song_json_file, songDifficulty: String = difficulty):
	super.loadSong(data,songDifficulty)
	loadStage(SONG.get('stage',''))
	
func loadSongObjects() -> void:
	camHUD.removeFilters()
	camOther.removeFilters()
	
	loadStageSprites(); #print('Loading Stage')
	
	_load_song_scripts(); #print('Loading Scripts')
	
	
	super.loadSongObjects() #print('Loading Song Objects')
	
	loadEventsScripts() #print('Loading Events')
	
	loadCharactersFromData() #print('Loading Characters')
	
	if !inModchartEditor:
		DiscordRPC.state = 'Now Playing: '+SongData.songName
		DiscordRPC.refresh()
	
func loadEventsScripts():
	for i in Paths.getFilesAtAbsolute(Paths.exePath+'/assets/custom_events',false,['gd'],true): FunkinGD.addScript('custom_events/'+i)
	
	var length = eventNotes.size()
	var i: int = 0
	while i < length:
		var event = eventNotes[i]
		i += 1
		var event_path ='custom_events/'+event.e
		FunkinGD.addScript(event_path)
		
		FunkinGD.callOnScripts(&'onLoadEvent',[event.e,event.v,event.t])
		FunkinGD.callScript(event_path,&'onLoadThisEvent',[event.v,event.t])
		if _is_first_event_load:
			FunkinGD.callOnScripts(&'onInitEvent',[event.e,event.v,event.t])
			FunkinGD.callScript(event_path,&'onInitLocalEvent',[event.v,event.t])
	
func startSong():
	super.startSong()
	if Conductor.songs: Conductor.songs[0].finished.connect(endSound)
	FunkinGD.callOnScripts(&'onSongStart')

func loadNextSong():
	var newSong = story_songs[0]
	story_songs.remove_at(0)
	if !story_song_notes.has(newSong): newSong = loadSong()

func seek_to(time: float, kill_notes: bool = true):super.seek_to(time,kill_notes)

#region Resume/Pause/End Song Methods
func resumeSong() -> void:
	if _isSongStarted: Conductor.resumeSongs()
	generateMusic = true
	process_mode = PROCESS_MODE_INHERIT
	onPause = false

func pauseSong(menu: bool = createPauseMenu) -> void:
	if !canPause: return
	if menu:
		if pauseState: return 
		create_pause_menu()
	generateMusic = false
	if _isSongStarted: Conductor.pauseSongs()
	process_mode = Node.PROCESS_MODE_DISABLED
	onPause = true
	

func create_pause_menu() -> PauseSubstate:
	if pauseState: return pauseState
	pauseState = PauseSubstate.new()
	pauseState.resume_song.connect(resumeSong.call_deferred)
	pauseState.restart_song.connect(restartSong.call_deferred)
	pauseState.exit_song.connect(endSound.call_deferred)
	add_sibling.call_deferred(pauseState)
	return pauseState

func restartSong(absolute: bool = true):
	Conductor.pauseSongs()
	if absolute: reloadPlayState(); return
	
	generateMusic = false
	TweenService.createTween(self,{&'songPosition': -Conductor.stepCrochet*24.0},1.0,'sineIn').finished.connect(
		func():
			for note in notes.members: note.kill()
			notes.members.clear()
			generateMusic = true
			onPause = false
	)

func endSound(skip_transition: bool = false) -> void:
	Conductor.pauseSongs()
	var results = FunkinGD.callOnScriptsWithReturn('onEndSong')
	if FunkinGD.Function_Stop in results or !canExitSong: return
	exitingSong = true
	canPause = false
	if isStoryMode and story_song_notes: loadNextSong()
	elif back_state: Global.swapTree(back_state.new(),!skip_transition)
#endregion

#endregion



const CopyThisValues = [
	&"seenCutscene",&"playAsOpponent",
	&"song_folder", &"song_json_file",
	&"difficulty",&"_from_mod"
]

func reloadPlayState(): ##Called when the game gonna restart the song
	for n in notes.members: n.kill()
	var state = get_script().duplicate().new()
	Global.swapTree(state,true)
	
	Global.onSwapTree.disconnect(destroy)
	Global.onSwapTree.connect(func():
		for vars in CopyThisValues: state[vars] = self[vars]
		destroy(false),CONNECT_ONE_SHOT
	)

#region Modding Methods
func chartEditor() -> void: 
	Global.doTransition().finished.connect(func():
		var chartEditor = ChartEditorScene.instantiate()
		Global.swapTree(chartEditor,false); 
		chartEditor.prev_scene = get_script()
		,CONNECT_ONE_SHOT
	)
	pauseSong(false)

func characterEditor():
	Global.doTransition().finished.connect(func():
		var editor = CharacterEditor.instantiate()
		editor.back_to = get_script()
		Global.swapTree(editor,false),CONNECT_ONE_SHOT
	)
	pauseSong(false)
#endregion

#region Video Methods
const FunkinVideo = preload("uid://w8ju6w7jofop")
func startVideo(path: Variant, isCutscene: bool = true) -> FunkinVideo:
	var video_player = FunkinVideo.new()
	video_player.load_stream(path)
	
	if !video_player.stream: return video_player
	
	camOther.add(video_player)
	if !isCutscene: return video_player
	if videoPlayer: videoPlayer.queue_free()
	
	videoPlayer = video_player
	canPause = false
	inCutscene = true
	
	videoPlayer.finished.connect(_on_cutscene_ends)
	return videoPlayer

func _on_cutscene_ends() -> void:
	inCutscene = false
	canPause = true
	seenCutscene = true
	FunkinGD.callOnScripts(&'onEndCutscene',[videoPlayer.stream.resource_name])
	videoPlayer.queue_free()
#endregion



#region Section Methods
func onSectionHit(sec: int = Conductor.section) -> void:
	if sec < 0: return
	
	var sectionData = ArrayUtils.get_array_index(SONG.get('notes',[]),sec)
	if !sectionData: return
	
	mustHitSection = !!sectionData.get('mustHitSection')
	gfSection = !!sectionData.get('gfSection')
	altSection = !!sectionData.get('altAnim')
	FunkinGD.mustHitSection = mustHitSection
	FunkinGD.gfSection = gfSection
	FunkinGD.altAnim = altSection
	
func detectSection() -> String: 
	return 'gf' if gfSection else ('boyfriend' if mustHitSection else 'dad')
#endregion

#region Character Methods
@abstract func addCharacterToList(_type,_character)
#Replaced in PlayState and PlayState3D
@abstract func changeCharacter(_t: int = 0, _character: StringName = 'bf')

func onSectionHitOnce(): if !isCameraOnForcedPos: moveCamera(detectSection())

func loadCharactersFromData(json: Dictionary = SONG) -> void:
	changeCharacter(2,json.get('gfVersion','gf'))
	changeCharacter(0,json.get('player1','bf'))
	changeCharacter(1,json.get('player2','bf'))

static func get_character_type_name(type: int) -> StringName:
	match type:
		1: return &'dad'
		2: return &'gf'
		_: return &'boyfriend'
#endregion

#region Stage Methods
func loadStage(stage: StringName):
	if curStage == stage: return
	FunkinGD.callOnScripts(&"onPreloadStage",stage)
	FunkinGD.curStage = stage
	curStage = stage
	
	stageJson = Stage.loadStage(stage)
	isPixelStage = stageJson.isPixelStage
	FunkinGD.callOnScripts(&"onLoadStage",stage)

func _check_stage_sprites_beat():
	for i in stageDanceSprites: pass

func loadStageSprites():
	if !stageJson: return
	
	var props = stageJson.get('props')
	if !props: return
	for data in props:
		var name = data.get('name','')
		var image = data.get('assetPath')
		var animations = data.get('animations')
		var sprite: FunkinSprite = FunkinSprite.new(!!animations)
		sprite.name = data.get('name','')
		
		var position = data.get('position'); 
		if position: position = Vector2(position[0],position[1])
		
		var scale = data.get('scale'); 
		if scale: sprite.setGraphicScale(Vector2(scale[0],scale[1]))
		
		var scroll = data.get('scroll');
		if scroll: sprite.scrollFactor = Vector2(scroll[0],scroll[1])
		
		sprite.antialiasing = !data.get('isPixel',false)
		
		sprite.position = position
		sprite.modulate.a = data.get('alpha',1.0)
		
		FunkinGD.spritesCreated[name] = sprite
		FunkinGD.addSprite(sprite,data.get('front',false))
		
		if image.begins_with("#"): sprite.modulate = Color(image);
		else: sprite.image.texture = Paths.texture(image)
		
		if animations:
			for anim in animations:
				var anim_name = anim.get('name','')
				var fps = anim.get('frameRate',24)
				var looped = anim.get('looped',false)
				var indices = anim.get('frameIndices')
				var offsets = anim.get('offsets'); offsets = Vector2(offsets[0],offsets[1]) if offsets else Vector2.ZERO
				
				if indices: sprite.animation.add_animation_by_prefix(anim_name,anim.prefix,fps,looped,indices)
				else: sprite.animation.add_animation_by_prefix(anim_name,anim.prefix,fps,looped)
				sprite.animation.set_anim_offset(anim_name,offsets)
			
			var startAnim = data.get('startingAnimation')
			if startAnim: sprite.animation.play(startAnim,true)

			var danceEvery = data.get('danceEvery')
			if danceEvery:
				stageDanceSprites.append(
					[
						danceEvery,
						sprite,
						sprite.animation.has_any_animations(['danceLeft','danceRight'])
					]
				)
	
#endregion

#region Game Over Methods
func gameOver() -> void: FunkinGD.inGameOver = true; inGameOver = true; pauseSong(false)

func isGameOverEnabled() -> bool:
	return canGameOver and health < 0.0 and not inGameOver and\
		not FunkinGD.Function_Stop in FunkinGD.callOnScriptsWithReturn('onGameOver')

func clear() -> void: 
	super.clear(); 
	_isSongStarted = false; camZooming = false;
	
	_is_first_event_load = true
	eventNotes.clear()
	EventNoteUtils.events_data.clear()
	
	camHUD.removeFilters(); camOther.removeFilters()
#endregion

#region Health Methods
func set_health(value: float) -> void:
	value = clampf(value,-1.0,2.0)
	if health == value: return
	
	
	health = value
	
	if isGameOverEnabled(): gameOver(); return
	
	var progress_h = value*0.5
	healthBar.progress = progress_h if playAsOpponent else 1.0 - progress_h
	
	
	var bar_state = 0.0
	if progress_h >= 0.7: bar_state = Icon.State.WINNING
	elif progress_h <= 0.3: bar_state = Icon.State.LOSING
	else: bar_state = Icon.State.NORMAL
	
	if bar_state == _healthBar_State: return
	_healthBar_State = bar_state
	updateIconsImage(bar_state)

##Set HealthBar angle(in degrees). See also [method @GlobalScope.rad_to_deg]
func setHealthBarAngle(angle: float):
	healthBar.rotation_degrees = angle
	_update_icons_cos_sin()
	updateIconsPivot()

func _update_icons_cos_sin() -> void: _icons_cos_sin = Vector2(cos(healthBar.rotation),sin(healthBar.rotation))
#endregion

#region Setters
func set_default_zoom(value: float) -> void: defaultCamZoom = value;

func _set_hide_hud(hide: bool) -> void:
	hideHud = hide
	FunkinGD.callOnScripts(&"onHideHud",hide)

func _set_play_opponent(isOpponent: bool = playAsOpponent) -> void:
	healthBar.flip = !isOpponent
	updateIconsImage()
	super._set_play_opponent(isOpponent)
#endregion

#region Camera methods
func moveCamera(target: StringName = 'boyfriend') -> void: FunkinGD.callOnScripts(&'onMoveCamera',[target])
#endregion


func _unhandled_input(event: InputEvent):
	if event is InputEventKey:
		FunkinGD.callOnScripts(&'onKeyEvent',[event])
		if !event.pressed or event.echo: return
		match event.keycode:
			KEY_ENTER: if canPause and not onPause: pauseSong.call_deferred()
			KEY_7: if isModding: chartEditor()
			KEY_8: if isModding: characterEditor()

func destroy(absolute: bool = true):
	FunkinGD.callOnScripts(&'onDestroy',[absolute])
	FunkinGD._clear_scripts()
	FunkinGD.game = null
	stageJson.clear()
	
	Paths.extraDirectory = ''
	
	camHUD.removeFilters()
	camOther.removeFilters()
	Paths.clearLocalFiles()
	Paths._clear_paths_cache()
	super.destroy(absolute)

func _property_get_revert(property: StringName) -> Variant:
	match property:
		'defaultCamZoom': return Stage.json.get('cameraZoom',1.0)
		'cameraSpeed': return Stage.json.get('cameraSpeed',1.0)
		'health': return 1.0
	return null
