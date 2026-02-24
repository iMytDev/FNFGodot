@tool
extends Node
const StreamNames = [&"Inst", &"OpponentVoice", &"Voices"]
const BEATS_PER_SECTION: int = 4

var songs: Array[AudioStreamPlayer]
var hasVoices: bool
var fixVoicesSync: bool

var songData: SongData = SongData.new()

var music_pitch: float = 1.0: set = _set_music_pitch

var is_playing: bool

var songPosition: float: set = _set_song_position
var songPositionDelayed: float #songPosition - ClientPrefs.data.songOffset
var songPositionSeconds: float ##[param songPosition] in seconds.

var songLength: float: set = _set_song_length
var songLengthSeconds: float

var step: int: set = _set_step
var step_float: float: set = _set_step_float

var beat: int: set = _set_beat
var beat_float: float: set = _set_beat_float

var section: int: set = _set_section
var section_float: float: set = _set_section_float


var beat_reduced: BeatsReduced = BeatsReduced.new()
var _beats_reduced_array: Array[BeatsReduced] = [beat_reduced]
var _beats_reduced_index: int = 0: set = _set_beat_reduced_index

var default_bpm_data = BPMData.new()
var bpm_data: BPMData = default_bpm_data
var _bpm_changes: Array[BPMData] = [default_bpm_data]
var _bpm_index: int = 0: set = _set_bpm_index


signal step_hit() ##Emiited when the step changes.

## Emitted every time the section is passed during a change.
## If the section changes from 3 to 6, this signal will be emitted for sections 4, 5, and 6
signal section_hit()

## Emitted once after the full section change is completed.
## Use this if you only need a single notification per section change.
signal section_hit_once() 

signal beat_hit() ##Emitted when the beat changes.
signal on_bpm_changes() ##Emitted when the bpms changes.

signal song_loaded() ##Emitted when the a song is loaded. 
signal song_position_changed() ##Emiited when the song position is changed.

#region Song methods
func _init() -> void: default_bpm_data.changed.connect(on_bpm_changes.emit)

func loadSongFromData(song_data: SongData):
	songData = song_data;
	loadSongsStreamsFromData(song_data)
	
	default_bpm_data.bpm = songData.data.get("bpm",120.0)
	detectBpmChanges()
	seek(0.0)

func loadSongsStreamsFromData(data: SongData):
	var audio_folder: String = data.audioFolder
	if !audio_folder: audio_folder = data.songName;
	loadSongsStreams(audio_folder, data.audioSuffix)


func loadSongsStreams(folder: String = '', suffix: String = '') -> void: ##Load [AudioPlayer]'s from the current song.
	if !folder: return
	var paths: Array = [
		['Inst'+suffix,'Inst'] if suffix else ['Inst'], 
		['Voices-Opponent'+suffix], 
		['Voices-Player','Voices'+suffix]
	]

	var opponent_name = songData.playerVocals
	if opponent_name:
		paths[1].append('Voices-'+opponent_name+suffix)
		paths[1].append('Voices-'+opponent_name.replace(' ','-').get_slice('-',0)+suffix)
	
	var player_name = songData.opponentVocals
	if player_name:
		paths[2].append('Voices-'+player_name+suffix,)
		paths[2].append('Voices-'+player_name.replace(' ','-').get_slice('-',0)+suffix)
	
	var stream_id: int = -1
	for p in paths:
		stream_id += 1
		for i in p: 
			var song = PathsStore.song(folder+'/'+i)
			if song: loadSong(song, StreamNames[stream_id]); break
	hasVoices = songs.size() > 1
	song_loaded.emit()

func loadSong(path_absolute: String, tag: String):
	var stream = Paths.audio_absolute(path_absolute);
	var audio = get_node_or_null(tag)
	if !audio:
		if !stream: return
		audio = AudioStreamPlayer.new()
		songs.append(audio)
		audio.name = tag
		add_child(audio)
	
	audio.pitch_scale = music_pitch
	audio.stream = stream
	if tag == &"Inst":
		songLengthSeconds = stream.get_length()
		songLength = songLengthSeconds*1000.0
	return

func sync_voices() -> void:
	if !hasVoices: return
	var index: int = 1
	while index < songs.size():
		var song = songs[index]
		if absf(song.get_playback_position() - songPositionSeconds) > 0.01: song.seek(songPositionSeconds)
		index += 1


func seek(pos: float) -> void: ##Set the current position of the song in milliseconds.
	pos = clampf(pos,0.0,songLength)
	songPosition = pos
	songPositionSeconds = pos * 0.001
	if !songs: return
	
	if songPosition < 0.0:
		for i in songs: if i: i.stop()
		return
	
	for i in songs: if i: i.seek(clampf(songPositionSeconds, 0.0, i.stream.get_length()))

func resumeSongs() -> void:
	if songPositionSeconds < 0.0: return
	for i in songs:  if i and songPositionSeconds < i.stream.get_length(): i.play(songPositionSeconds)

func pauseSongs() -> void: for song in songs: song.stop() ##Pause the streams.

func stopSongs(delete: bool = false) -> void: ##Stop the streams.
	if !delete:
		for song in songs: song.stop()
		songPosition = 0
		return
	
	for song in songs: remove_child(song); song.queue_free()
	songs.clear()

func clearSong(absolute: bool = true) -> void: ##Clear all the songs created
	stopSongs(true)
	if !absolute: _bpm_index = 0; _beats_reduced_index = 0; return
	_clear_changes()
	default_bpm_data.bpm = 0

#endregion

#region Section Methods
func get_section(_pos: float, bpm_info: BPMData = bpm_data, beats_reduced: BeatsReduced = beat_reduced) -> float:
	if !bpm_info.bpm: return 0
	if beats_reduced: _pos += beats_reduced.time_offset
	return bpm_info.section + ( (_pos - bpm_info.time) / bpm_info.sectionCrochet)

func get_section_data(sec: int = section) -> Dictionary: 
	var notes = songData.sections; return notes[sec] if notes and sec < notes.size() else {}

func get_section_count() -> int: 
	var b = _bpm_changes.back(); return b.section + ((songLength - b.time) / b.sectionCrochet)

func get_section_time(_section: int = section) -> float:
	if !_section: return 0.0
	var size = _bpm_changes.size()
	var index: int = 0
	var time: float = 0.0
	var max_section = 0
	var bpm_change
	while index < size:
		var i = _bpm_changes[index]
		if i.section > section: break
		time += (max_section - i.section) * i.sectionCrochet
		bpm_change = i
		index += 1
	time += (_section - max_section) * bpm_change.sectionCrochet
	return time + get_beats_reduced_at(_section, &"section").time_offset


#endregion

#region Beat Methods
func get_beat(pos: float, bpm_info: BPMData = bpm_data) -> float: 
	if !bpm_info.bpm: return 0
	return bpm_info.beat + ((pos - bpm_info.time) / bpm_info.crochet) 

func _reduce_section_beats(section: int, beats: int, _bpm: float = bpm_data.bpm) -> void:
	if beats == BEATS_PER_SECTION: return
	var beats_reduced: int = BEATS_PER_SECTION - beats
	var data: BeatsReduced = BeatsReduced.new()
	data.time = get_section_time(section)
	data.section = section
	data.time_offset = BPMData.get_crochet(_bpm) * beats_reduced
	data.cutback = beats_reduced

	if _beats_reduced_array: 
		var last = _beats_reduced_array.back()
		data.time_offset += last.time_offset
		data.cutback += last.cutback
	_beats_reduced_array.append(data)

func get_beats_reduced_at(position: float,key: StringName = &'section', start_index: int = 0) -> BeatsReduced:
	return _beats_reduced_array[_find_beats_reduced_index(position, key, start_index)]

func _find_beats_reduced_index(position: float, key: StringName = &'section', start_index: int = 0) -> int:
	while start_index and position < _beats_reduced_array[start_index-1][key]: 
		start_index -= 1;
	while start_index < _beats_reduced_array.size()-1 and position > _beats_reduced_array[start_index+1][key]: 
		start_index += 1;
	return start_index
#endregion

#region Step Methods 
func get_step(_position: float, bpm_changes: BPMData = bpm_data) -> float:
	if !bpm_changes.bpm: return 0.0
	return bpm_changes.step + ((_position - bpm_changes.time) / bpm_changes.stepCrochet) 

func get_step_count() -> int:
	var b = _bpm_changes.back(); 
	if !b.bpm: return 0
	return b.step + ((songLength - b.time) / b.stepCrochet)

func get_step_time(_step: float) -> float:
	var bpm_info: BPMData
	var max_step: float
	var time: float = 0.0
	var size = _bpm_changes.size()
	
	var index: int = 0
	while index < size:
		bpm_info = _bpm_changes[index];
		time += bpm_info.time;
		max_step = bpm_info.step
		index += 1
	return time + (_step - max_step) * bpm_info.stepCrochet

func get_step_section(_section: int) -> int:
	var beats_reduced = get_beats_reduced_at(_section)
	return (_section*BEATS_PER_SECTION - beats_reduced.cutback) * BEATS_PER_SECTION
#endregion

#region Bpm Methods
func _update_rhythm() -> void:
	step_float = get_step(songPosition)
	beat_float = step_float * 0.25
	section_float = get_section(songPosition)

func _clear_changes() -> void:
	bpm_data = default_bpm_data
	_bpm_changes.resize(1)
	
	beat_reduced = _beats_reduced_array[0]
	_beats_reduced_array.resize(1)

func detectBpmChanges() -> void:
	_clear_changes()
	
	var sectionBpm: float = _bpm_changes[0].bpm
	var bpm_section: int = 0
	
	var notes = songData.data.get(&"notes"); if !notes: return
	var length = notes.size()
	while bpm_section < length:
		var i = notes[bpm_section]
		var sectionBeats: int = int(i.get(&"sectionBeats", BEATS_PER_SECTION))
		if i.changeBPM and i.bpm != sectionBpm: _change_bpm_at(bpm_section,i.bpm); sectionBpm = i.bpm
		if sectionBeats < BEATS_PER_SECTION: _reduce_section_beats(bpm_section,sectionBeats,sectionBpm)
		bpm_section += 1
#endregion

#region BPM Changes
func _change_bpm_at(_section: int, newBpm: float) -> void:
	var data: BPMData = BPMData.new()
	data.bpm = newBpm
	data.time = get_section_time(_section)
	data.step = get_step_section(_section)
	data.beat = data.step * 0.25
	data.section = _section
	_bpm_changes.append(data)

func get_bpm_changes_at(position: float, key: StringName = &'step', from: int = _bpm_index) -> BPMData:
	return _bpm_changes[_find_current_change_index(position, key, from)]

func removeBpmChange(section: int): 
	for i in _bpm_changes: if i.section == section: _bpm_changes.erase(i); break


func _find_current_change_index(value: float = step,key: StringName = &'step', from: int = _bpm_index) -> int:
	if value < 0.0: return 0
	while from and value <= _bpm_changes[from-1][key]: from -= 1; 
	while from < _bpm_changes.size()-1 and value >= _bpm_changes[from+1][key]: from += 1;
	return from
#endregion

#region Setters
func _set_song_position(position: float) -> void:
	songPosition = position
	songPositionDelayed = position - ClientPrefs.data.songOffset
	_update_rhythm()
	if fixVoicesSync: sync_voices()
	song_position_changed.emit()

func _set_section(s: int) -> void:
	if section == s: return
	while section > s: section -= 1; section_hit.emit()
	while section < s: section += 1; section_hit.emit()
	section_hit_once.emit()
	_beats_reduced_index = _find_beats_reduced_index(s,&'section',_beats_reduced_index)
	_bpm_index = _find_current_change_index(section,&"section", _bpm_index)
func _set_beat(b: int) -> void:
	if beat == b: return 
	beat = b; beat_hit.emit();
func _set_step(val: int) -> void:
	if step == val: return
	step = val; step_hit.emit();

func _set_beat_reduced_index(i: int): 
	if i == _beats_reduced_index: return
	_beats_reduced_index = i
	beat_reduced = _beats_reduced_array[i]
func _set_bpm_index(i: int):
	if i == _bpm_index: return
	_bpm_index = i
	bpm_data = _bpm_changes[_bpm_index]
	on_bpm_changes.emit()

func _set_section_float(val: float) -> void: section_float = val; section = int(val)
func _set_beat_float(val: float) -> void: beat_float = val; beat = int(val)
func _set_step_float(val: float) -> void: step_float = val; step = int(val)
func _set_song_length(val: float) -> void: songLength = val; songLengthSeconds = val*0.001
func _set_music_pitch(p: float): music_pitch = p; for i in songs: if i: i.pitch_scale = p

#endregion

func _process(_d) -> void:
	if !songs: is_playing = false; return
	
	var inst = songs[0]
	is_playing = inst.playing; if !is_playing: return;
	songPositionSeconds = inst.get_playback_position()
	songPosition = songPositionSeconds * 1000.0
