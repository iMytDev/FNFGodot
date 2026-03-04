@icon("res://icons/NoteSustain.svg")
class_name NoteSustain extends Note ##Sustain Base Note Class
const NoteHit = preload("uid://dx85xmyb5icvh")
var isBeingDestroyed: bool
var noteParent: NoteHit ##Sustain's Note Parent

var _hit_time: float

var region: Rect2
var _height: float

var end_sustain: NoteSustain

var _sustain_fill: float
var _sustain_filled: bool
var _is_flipped: bool
func _init(data: int, is_end: bool = false) -> void:
	isEndSustain = is_end
	splashStyle = &'HoldNoteSplashes'
	isSustainNote = true
	splashDisabled = is_end
	texture_repeat = TEXTURE_REPEAT_ENABLED
	multAlpha = ClientPrefs.data.sustain_alpha
	copyAngle = false
	super(data)

func _reload_note_without_data() -> void: 
	loadSustainFrame(); 
	image.scale.x = noteScale

func _reload_note_from_data(d: Dictionary) -> void:
	image.use_region_offset = true
	var p = d.get(&'prefix')
	if p: animation.add_animation_by_prefix(_get_sus_name(), p, d.get(&'fps',24.0), true); return
	
	var _region = d.get(&'region')
	if !_region: loadSustainFrame(); return
	
	region = Rect2(_region[0],_region[1],_region[2],_region[3]);
	image.region_rect = region
	pivot_offset = region.size * 0.5 

func _get_sus_name() -> StringName: return &'holdEnd' if isEndSustain else &'hold'

func _get_style_prefix_name() -> StringName:
	if !styleData: return &""
	var _name = directions[noteData]; if isEndSustain: _name += 'End'
	if styleData.data.has(_name): return _name
	
	if isEndSustain: _name = &"defaultEnd"
	else: _name = &'default'
	
	if styleData.data.has(_name): return _name
	return &''

func loadSustainFrame():
	var rect = Rect2(Vector2.ZERO, imageSize)
	if !styleData.is_full_image(noteDirection):
		var frame: int = noteData * 2
		var cut: int = int(imageSize.x) / (styleData.keyCount * 2)
		rect.position.x = cut * (frame + 1 if isEndSustain else frame)
		rect.size.x = cut
	
	region = rect
	image.region_rect = region
	pivot_offset.x = region.size.x * 0.5
	image.use_region_offset = false

func updateNote() -> void:
	distance = strumTime - Conductor.songPositionDelayed
	if isBeingDestroyed and _hit_time: _update_hit_time()
	updateSustain()
	canBeHit = _can_hit()
	follow_strum()

func _update_hit_time() -> void: _hit_time = maxf(0.0,_hit_time-get_process_delta_time() * Conductor.music_pitch); 

func _get_note_style_key() -> StringName: return &"holdNote"

func _get_sustain_height() -> float:
	if isEndSustain: 
		if image.use_region_offset: 
			return image.region_rect.size.y
		return imageSize.y
	
	return _height / (scale.y * image.scale.y)
	

#region Updaters
func updateSustain():
	var full_scale = scale.y * image.scale.y
	var _sus_height: float = _get_sustain_height()
	if distance >= 0.0: _fill_sustain(_sus_height, 0.0); return
	
	if isBeingDestroyed:
		_sustain_fill = real_distance
		var fill = absf(real_distance / full_scale)
		_fill_sustain(_sus_height - fill, fill)
		_sustain_filled = distance < -sustainLength
	real_distance -= _sustain_fill

func _update_note_speed() -> void:
	super()
	_is_flipped = _real_note_speed < 0.0
	
	if _is_flipped: image.scale.y = -noteScale
	else: image.scale.y = noteScale
	
	if !isEndSustain: 
		_height = sustainLength * _real_note_speed; updateSustain();

func _fill_sustain(height: float, dist: float) -> void:
	height = maxf(height, 0.0)
	
	if image.use_region_offset:
		image.region_rect_offset.size.y = height - image.region_rect.size.y
		image.region_rect_offset.position.y = dist
	else:
		image.region_rect.size.y = height
		image.region_rect.position.y = dist
#endregion

func resetNote() -> void:
	super()
	_sustain_fill = 0.0
	_sustain_filled = false
	canBeHit = false
	isBeingDestroyed = false
	_hit_time = 0.0
	splashName = &'holdNoteCover'

func follow_strum(strum: StrumNote = strumNote) -> void: ##Update the Note position from the his [param strumNote].
	super(strum)
	rotation_degrees = -strumNote.direction
	if copyScale: scale = strum.scale * noteScale

func get_note_offset() -> Vector2:
	var off = super()
	off.x -= pivot_offset.x * scale.x * image.scale.x
	if strumNote: off += strumNote.pivot_offset * strumNote.scale * strumNote.image.scale
	return off

#region Hit
func _can_hit() -> bool: 
	if missed: return false
	var hit = distance <= 15.0 and (!noteParent or noteParent.wasHit);
	if isEndSustain: return hit and !isBeingDestroyed;
	return hit and _hit_time <= 0.0 and (!end_sustain or !end_sustain.isBeingDestroyed)

func _on_hit() -> void: 
	isBeingDestroyed = true; wasHit = true; 
	if !isEndSustain: 
		_hit_time = (1.0 - (Conductor.step_float - Conductor.step)) * Conductor.bpm_data.stepCrochetMs;
#endregion

func set_pivot_offset(value: Vector2) -> void: value.y = 0.0; super(value)
