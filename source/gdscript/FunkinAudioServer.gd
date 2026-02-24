class_name FunkinAudioServer extends FunkinInternal
static var soundsPlaying: Dictionary[StringName,AudioStreamPlayer] ##[b]Sounds[/b] created using [method playSound] function.

static func is_audio(value: Object): return value and value.get_class().begins_with('AudioStreamPlayer')

static func getSoundTime(sound: Variant) -> float:##Get the Sound Time.
	if sound is String and sound in soundsPlaying: sound = soundsPlaying[sound]
	return sound.get_playback_position() if is_audio(sound) else 0.0

static func setSoundPosition(sound: Variant, position: float):
	sound = _get_audio_player(sound)
	if sound: sound.seek(position)

static func setSoundVolume(sound: Variant, volume: float = 1) -> void:
	if sound is String: sound = FunkinProperty.get_property(sound)
	if !is_audio(sound): return
	sound.volume_db = -80 + (80*volume)

static func _create_audio(stream: Variant, tag: String = '') -> AudioStreamPlayer:
	var audio = _create_audio_player(stream); 
	if !audio: 
		return
	
	_add_game_node(audio); 
	if !tag: 
		return audio
	
	audio.name = tag
	soundsPlaying[tag] = audio
	audio.finished.connect(stopSound.bind(tag),CONNECT_ONE_SHOT)
	return audio

##Play a sound. [code]path[/code] can be a [String] or a [AudionStreamOggVorbis].
##[br]Example of code: [codeblock]
##playSound('noise',1.0,'noise_sound')
##
##var audio = Paths.sound('noise2')
##playSound(audio,1.0,'noise_sound2')
##[/codeblock]
static func playSound(path, volume: float = 1.0, tag: String = "", force: bool = false, loop: bool = false) -> AudioStreamPlayer:
	if !path: return null
	var audio: AudioStreamPlayer = soundsPlaying.get(tag)
	
	if !audio: audio = _create_audio(path,tag)
	elif audio.playing and !force: return audio
	
	if audio.stream: audio.stream.loop = loop
	
	audio.play(0)
	audio.volume_db = linear_to_db(volume)
	return audio

static func stopSound(tag: StringName):
	if !soundsPlaying.has(tag): return
	soundsPlaying[tag].stop()
	soundsPlaying.erase(tag)

static func _create_audio_player(stream: Variant):
	if !stream is AudioStream: stream = Paths.sound(stream); if !stream: return
	var audio = AudioStreamPlayer.new()
	audio.stream = stream;
	audio.finished.connect(audio.queue_free)
	return audio
	
static func _get_audio_player(audio: Variant) -> AudioStreamPlayer:
	if audio is String or audio is StringName: audio = FunkinProperty.get_property(audio)
	return audio if is_audio(audio) else null
static func clear():
	soundsPlaying.clear()
