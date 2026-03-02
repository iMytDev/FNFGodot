@tool
@abstract
class_name PlayStateBase extends StrumState 
##A Base script for Playstate.
enum GameMode{
	MODE_2D,
	MODE_3D
}
const CharacterEditor = preload("uid://droixhbemd0xd")
const ChartEditorScene = preload("uid://bw5vas6axpdqk")

const Bar = preload("uid://cesg7bsxvgdcm")
const Stage = preload("uid://dh7syegxufdht")
static var back_state = preload("uid://dbcawd2so03ht")

const PERSISTENT_PROPERTIES = [
	&"SONG",
	&"unspawnNotes",
	&"eventNotes",
	&"seenCutscene",
	&"playAsOpponent"
]


#region Camera Properties
@export_group('Camera')
@onready var camHUD: FunkinCamera2D
@onready var camOther: FunkinCamera2D
@export var camZooming: bool ##If [code]true[/code], the camera adds a zoom every [member bumpStrumBeat] beats and the zoom will back automatically.

@export var camFollowPosition: bool = true
@export var zoomSpeed: float = 1.0: set = set_zoom_speed

var cameras: Array[Node] #Used in external scripts.
var cameraSpeed: float = 1.0: set = set_camera_speed
var _real_camera_speed: float = 3.5
var _real_zoom_speed: float = 3.0

var isCameraOnForcedPos: bool
@export var defaultCamZoom: float = 1.0: set = set_default_zoom
#endregion

@export_group('Play Options')
var gameMode: GameMode = GameMode.MODE_2D
var altSection: bool

var health: float = 1.0: set = set_health

@export var singAnimations: Array = [&"singLEFT",&"singDOWN",&"singUP",&"singRIGHT"]

@export_range(0.0,8.0,0.25) var bumpStrumBeat: float = 4.0 ##The amount of beats for the camera to give a "beat" effect.

@export var canExitSong: bool = true
@export var canPause: bool = true
@export var createPauseMenu: bool = true
@export var canGameOver: bool = true
var onPause: bool
var inGameOver: bool

#region Scripts Properties
var curStage: StringName
var stageJson: Dictionary = Stage.getStageBase()
var stageDanceSprites: Array[Array]

@export_subgroup('Scripts')
@export var loadScripts: bool = true
@export var loadStageScript: bool = true
@export var loadSongScript: bool = true

@export_subgroup('Events')
@export var loadSongEvents: bool = true
@export var generateEvents: bool = true

var eventNotes: Array[EventNote]
var _event_index: int = 0
var _is_first_event_load: bool = true
#endregion


#region Gui
@export_group("Hud Elements")
@export var hideHud: bool: set = _set_hide_hud
#endregion

#region Game Options
@export_category('Story Mode')
var story_song_notes: Dictionary
var story_songs: PackedStringArray
var isStoryMode: bool
#endregion

@export_category("Song Data")
var mustHitSection: bool: set = set_must_hit_section ##When the focus is on the opponent.
var gfSection: bool: set = set_gf_section ##When the focus is on the girlfriend.

var inst: AudioStreamPlayer
var voices: AudioStreamPlayer
var voice_opponent: AudioStreamPlayer

@export_category("Cutscene")
var seenCutscene: bool
var skipCutscene: bool = true
var inCutscene: bool
var videoPlayer: VideoStreamPlayer

func _init(data: SongData = null): super(data); hideHud = ClientPrefs.data.hideHud

func _ready():
	FunkinGD.reset()
	FunkinGD.GameMode = gameMode
	FunkinGD.game = self
	FunkinGD.owner = self
	
	if Engine.is_editor_hint(): 
		_setup_cameras(); 
		super(); 
		return
	_connect_rhythm_signals()
	_setup_cameras()
	super()
	FunkinGD.callOnScripts(&'onCreatePost')

func _setup_cameras() -> void:
	camHUD = _get_or_add_camera(^"camHUD");
	camOther = _get_or_add_camera(^"camOther")

func _get_or_add_camera(cam_path: NodePath, cam_class: Object = FunkinCamera2D) -> Node:
	var cam = get_node_or_null(cam_path); 
	if !cam:
		cam = cam_class.new(); cam.name = cam_path.get_name(cam_path.get_name_count()-1)
		add_child(cam)
		if Engine.is_editor_hint(): cam.owner = get_tree().edited_scene_root
	cameras.append(cam)
	return cam

func _connect_rhythm_signals(): 
	Conductor.beat_hit.connect(onBeatHit); 
	Conductor.section_hit.connect(onSectionHit)
	Conductor.section_hit_once.connect(onSectionHitOnce)
	Conductor.step_hit.connect(onStepHit)
	Conductor.on_bpm_changes.connect(_on_bpm_changes)
	Conductor.song_loaded.connect(_on_song_loaded)

func _on_song_loaded():
	inst = Conductor.get_node_or_null(^"Inst")
	voices = Conductor.get_node_or_null(^"Voices")
	voice_opponent = Conductor.get_node_or_null(^"VoicesOpponent")

func _on_bpm_changes():
	FunkinGD.bpm = Conductor.bpm_data.bpm
	FunkinGD.stepCrochet = Conductor.bpm_data.stepCrochet
	FunkinGD.stepCrochetMs = Conductor.bpm_data.stepCrochetMs
	FunkinGD.crochet = Conductor.bpm_data.crochet
	FunkinGD.callOnScripts(&"onBPMChanges")


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if camZooming: camHUD.zoom = lerpf(camHUD.zoom,camHUD.default_zoom,delta*_real_zoom_speed*Conductor.music_pitch)
	FunkinGD.callOnScripts(&'onUpdate', delta)
	super(delta)
	FunkinGD.callOnScripts(&'onUpdatePost', delta)

#region Gui
func _setup_hud() -> void:
	super(); camHUD.add(uiGroup,true); FunkinGD.callOnScripts(&"onSetupHud")

func createMobileGUI():
	super(); FunkinGD.callOnScripts(&"createMobileGUI")
#endregion

#region Section Methods
func onSectionHit() -> void:
	FunkinGD.curSection = Conductor.section
	FunkinGD.callOnScripts(&"onSectionHit")
	if Conductor.section < 0: return
	var sectionData = Conductor.get_section_data(Conductor.section); if !sectionData: return
	mustHitSection = !!sectionData.get('mustHitSection')
	gfSection = !!sectionData.get('gfSection')
	altSection = !!sectionData.get('altAnim')
	FunkinGD.mustHitSection = mustHitSection
	FunkinGD.gfSection = gfSection
	FunkinGD.altAnim = altSection
	moveCamera()

func onSectionHitOnce(): FunkinGD.callOnScripts(&"onSectionHitOnce")

func detectSection() -> StringName: 
	return &'gf' if gfSection else (&'boyfriend' if mustHitSection else &'dad')
#endregion

#region Beat Methods
##Do screen beat effect. Also used in PlayState2D and 3D.
func screenBeat(multi: float = 1.0) -> void: camHUD.zoom += 0.03 * multi 


func onBeatHit() -> void:
	FunkinGD.curBeat = Conductor.beat
	if !can_process(): return
	charactersDance()
	if camZooming and !fmod(Conductor.beat,bumpStrumBeat): screenBeat()
	FunkinGD.callOnScripts(&"onBeatHit")

func onStepHit(): 
	FunkinGD.curStep = Conductor.step
	FunkinGD.callOnScripts(&"onStepHit")
#endregion

#region Note Methods
#func precacheSplash(style: StringName, prefix: StringName): pass

func createSplash(note) -> NoteSplash:
	var s = super(note); FunkinGD.callOnScripts(&'onSplashCreated', s); return s

func createStrum(i: int) -> StrumNote:
	var s = super(i); FunkinGD.callOnScripts(&'onStrumCreated', s); return s

func spawnNote(note): super(note); FunkinGD.callOnScripts(&'onSpawnNote',[note])

func reloadNotes():
	var types = SONG.data.get(&'noteTypes')
	if types: for i in types: loadExternalScript('custom_notetypes/'+i)
	super()

func reloadNote(note: Note):
	super(note)
	note.hitAnim = singAnimations[note.noteData]
	FunkinGD.callOnScripts(&'onLoadNote', note)
	if !note.noteType: return
	
	var path = 'custom_notetypes/'+note.noteType+'.gd'
	FunkinGD.callScript('assets/'+path,&'onLoadThisNote', note)
	FunkinGD.callScript(path,&'onLoadThisNote', note)

func load_notes(): super(); if loadSongEvents: loadEvents()

func loadEvents():
	if eventNotes: _is_first_event_load = false; return
	
	var events_to_load = SONG.data.get('events',[])
	var events_json = Paths.loadJson(SONG.json_folder+'/events.json')
	
	
	if events_json:
		if events_json.get('song') is Dictionary: events_json = events_json.song
		events_to_load.append_array(events_json.get('events',[]))
	
	eventNotes = EventNote.loadEventsFromChart(events_to_load,gameMode)
	_is_first_event_load = true

func updateNote(note: Note) -> bool:
	FunkinGD.callOnScripts(&'onPreUpdateNote', note)
	var updated = super(note)
	FunkinGD.callOnScripts(&'onUpdateNote', note)
	return updated

func _process_notes() -> void: super(); if generateEvents: _process_events()

func _process_events():
	while _event_index < eventNotes.size():
		var e = eventNotes[_event_index]; if e.t > _songPos: break
		_event_index += 1
		if e.opponent and playAsOpponent or e.player and !playAsOpponent: 
			trigger_event(e.e, e.v)

func trigger_event(event: StringName, values: Dictionary) -> void:
	FunkinGD.callScript("custom_events/"+event, &"onLocalEvent", values)
	FunkinGD.callOnScripts(&"onEvent", event, values)

func preHitNote(note: Note):
	if !note: return
	note.hitCharacter = getCharacterFromNote(note)
	if note.noteType:
		FunkinGD.callScript('custom_notetypes/'+note.noteType+'.gd',&'onPreHitThisNote',[note])
	
	if isPlayerNote(note): FunkinGD.callOnScripts(&'onPlayerPreHitNote', note)
	FunkinGD.callOnScripts(&'goodNoteHitPre' if note.mustPress else &'opponentNoteHitPre',[note])
	FunkinGD.callOnScripts(&'onPreHitNote', note)
	if !note.mustPress: camZooming = true
	super(note)

func hitNote(note: Note) -> void:
	if !note: return
	if note.mustPress != playAsOpponent: health += note.hitHealth
	if !note.noAnimation: singCharacterFromNote(note)
	
	var voice: AudioStreamPlayer
	if note.mustPress: 
		voice = voices
	else:
		voice = voice_opponent
		if !voice: voice = voices
	if voice: voice.volume_db = 0
	
	
	if note.noteType:
		FunkinGD.callScript(
			'custom_notetypes/'+note.noteType+'.gd',
			&'onHitThisNote',
			[note]
		)
	if isPlayerNote(note): FunkinGD.callOnScripts(&'onPlayerHitNote', note)
	FunkinGD.callOnScripts(&'goodNoteHit' if note.mustPress else &'opponentNoteHit', note)
	FunkinGD.callOnScripts(&'onHitNote', note)
	super(note)

@abstract func singMissCharacterFromNote(_note: Note) -> void
@abstract func singCharacter(character, anim_name: StringName) -> void
@abstract func singCharacterFromNote(note: Note) -> void

@abstract func getCharacterFromNote(note: Note) -> Node
@abstract func get_focus_position(char)

func noteMiss(note, character: Variant = null) -> void:
	health -= note.missHealth
	var audio: AudioStreamPlayer = voices if note.mustPress else voice_opponent
	if audio: audio.volume_db = -80
	super(note)
	FunkinGD.callOnScripts(&'onNoteMiss', note, character)
#endregion

#region Script Methods
func _load_scripts():
	if loadStageScript: loadExternalScript('stages/'+curStage+'.gd')
	if loadSongScript: FunkinGD.load_scripts_from_dir_absolute(SONG.json_folder)
	if loadScripts: FunkinGD.load_scripts_from_dir('scripts')
#endregion

#region Song Methods
func _load_song():
	super()
	var sections = SONG.data.get(&"notes")
	if !sections: return
	sections = sections[0]; 
	gfSection = sections.get(&'gfSection',false); 
	mustHitSection = sections.get(&"mustHitSection",false)

func _load_song_objects() -> void:
	print(SONG.data.get("stage",""))
	_load_scripts()
	super()
	loadEventsScripts()
	if !inModchartEditor and DiscordRPC.get_is_discord_working():
		DiscordRPC.details = ''
		DiscordRPC.state = 'Now Playing: '+Conductor.songData.songName
		DiscordRPC.refresh()
	
func loadEventsScripts():
	for i in PathsDir.get_files_at_absolute(PathsStore.assetsPath+'/assets/custom_events',false,['gd'],true): FunkinGD.addScript(i,'custom_events/'+i)
	
	var length = eventNotes.size()
	var i: int = 0
	while i < length:
		var event = eventNotes[i]
		i += 1
		var event_path = 'custom_events/'+event.e+'.gd'
		var script = loadExternalScript(event_path)
		
		FunkinGD.callOnScripts(&'onLoadEvent', event.e,event.v,event.t)
		FunkinGD.callScript(script,&'onLoadThisEvent', event.v,event.t)
		if _is_first_event_load:
			FunkinGD.callOnScripts(&'onInitEvent', event.e,event.v,event.t)
			FunkinGD.callScript(script,&'onInitLocalEvent', event.v,event.t)

#Overrided in PlayState2D and 3D
func loadExternalScript(path: String) -> Object: return FunkinGD.addScript(path)

func startSong() -> void:
	super()
	if Conductor.songs: Conductor.songs[0].finished.connect(endSound)
	FunkinGD.callOnScripts(&'onSongStart')

func loadNextSong() -> void:
	var newSong = story_songs[0]
	story_songs.remove_at(0)
	if !story_song_notes.has(newSong): newSong = _load_song()

#region Resume / Pause / End Song Methods
func resumeSong() -> void:
	if _is_song_start: Conductor.resumeSongs()
	generateMusic = true
	process_mode = PROCESS_MODE_INHERIT
	onPause = false

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
	elif back_state: exit(skip_transition)
		

func exit(skip_transition: bool = false):
	SceneManager.on_scene_changed.connect(destroy,CONNECT_ONE_SHOT)
	SceneManager.change_scene(back_state.new(), !skip_transition)
#endregion

#endregion

@abstract func get_restart_object() -> Object

##Restart the Song
func reloadPlayState(transition: bool = true):
	if transition: 
		var trans = FunkinTransition.create_transition()
		trans.start_trans().finished.connect(_reload_playstate)
	else: _reload_playstate()

func _reload_playstate():
	var scene = SONG.packedScene
	if scene: scene = load(scene)
	if !scene: scene = get_restart_object(); if !scene: return
	
	var state
	if scene is PackedScene: state = scene.instantiate()
	else: state = scene.new()
	
	for vars in PERSISTENT_PROPERTIES: state.set(vars,self.get(vars))
	
	destroy(false)
	SceneManager.change_scene(state,false)

#region Modding Methods
func chartEditor() -> void: 
	Global.doTransition().finished.connect(_change_to_chart_editor,CONNECT_ONE_SHOT)
	set_process(false)

func _change_to_chart_editor():
	var chartEditor = ChartEditorScene.instantiate()
	chartEditor.song_data = SONG
	destroy(false)
	SceneManager.change_scene(chartEditor,false); 

func characterEditor():
	Global.doTransition().finished.connect(_change_character_editor,CONNECT_ONE_SHOT)
	set_process(false)

func _change_character_editor():
	var editor = CharacterEditor.instantiate()
	editor.back_to = get_script()
	SceneManager.change_scene(editor,false)

#endregion

#region Video Methods
func startVideo(path: Variant, isCutscene: bool = true) -> FunkinVideo:
	var video_player = FunkinVideo.new()
	video_player.load_stream(path); 
	if !video_player.stream: return video_player
	
	camOther.add(video_player)
	if !isCutscene: return video_player
	
	if videoPlayer: videoPlayer.queue_free()
	
	canPause = false; 
	inCutscene = true
	FunkinGD.inCutscene = false
	videoPlayer = video_player; videoPlayer.finished.connect(_on_cutscene_ends)
	return videoPlayer

func _on_cutscene_ends() -> void:
	inCutscene = false
	canPause = true
	seenCutscene = true
	FunkinGD.inCutscene = false
	FunkinGD.seenCutscene = true
	FunkinGD.callOnScripts(&'onEndCutscene', videoPlayer.stream.resource_name)
	videoPlayer.queue_free()
#endregion




@abstract func load_stage(stage: String)
#region Character Methods
@abstract func charactersDance()
@abstract func get_char_stage_position(char: StringName)

static func get_character_type_name(type: int) -> StringName:
	match type:
		1: return &'dad'
		2: return &'gf'
		_: return &'boyfriend'
#endregion



#region Game Over Methods
func clear() -> void: 
	super();
	
	_is_song_start = false; 
	camZooming = false;
	
	_is_first_event_load = true
	eventNotes.clear()
#endregion

#region Health Methods
func set_health(value: float) -> void:
	value = clampf(value,-1.0,2.0)
	if health == value: return
	health = value
	FunkinGD.callOnScripts(&"onHealthChanged",health)
#endregion

#region Setters
func set_must_hit_section(hit: bool):
	if mustHitSection == hit: return
	mustHitSection = hit; 

func set_gf_section(gf_sec: bool):
	if gf_sec == gfSection: return
	gfSection = gf_sec;

func set_zoom_speed(val: float): zoomSpeed = val; _real_zoom_speed = val * 3.0
func set_camera_speed(val: float) -> void: cameraSpeed = val; _real_camera_speed = 3.5*val

func set_default_zoom(value: float) -> void: defaultCamZoom = value;
func _set_botplay(is_botplay: bool) -> void: super(is_botplay); FunkinGD.botPlay = is_botplay
func _set_hide_hud(hide: bool) -> void:
	FunkinGD.hideHud = hide; hideHud = hide; FunkinGD.callOnScripts(&"onHideHud", hide)

func _set_play_opponent(isOpponent: bool = playAsOpponent) -> void: 
	super(isOpponent); FunkinGD.playAsOpponent = isOpponent; FunkinGD.callOnScripts(&"onPlayerSideChanged")
#endregion

#region Camera methods
@abstract func moveCamera(target: StringName = detectSection()) -> void
#endregion


func _unhandled_input(event: InputEvent):
	if event is InputEventKey:
		FunkinGD.callOnScripts(&'onKeyEvent', event)
		if !event.pressed or event.echo: return
		match event.keycode:
			KEY_7: if isModding: chartEditor()
			KEY_8: if isModding: characterEditor()
	super(event)

func destroy(absolute: bool = true):
	FunkinGD.callOnScripts(&'onDestroy', absolute)
	FunkinGD._clear_scripts()
	FunkinGD.game = null
	FunkinGD.owner = null
	stageJson.clear()
	
	PathsStore.extraDirectory = ''
	
	camHUD.controller.clear_filters()
	camHUD.controller.clear_filters()
	Paths._clear_paths_cache()
	if absolute: EventData.clear()
	if isModding:
		Character.clear_characters()
	super(absolute)

func _property_can_revert(property: StringName) -> bool:
	match property:
		&'defaultCamZoom',&"cameraSpeed",&"health": return true
	return false

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&'defaultCamZoom': return stageJson.get(&'cameraZoom',1.0)
		&'cameraSpeed': return stageJson.get(&'cameraSpeed',1.0)
		&'health': return 1.0
	return null
