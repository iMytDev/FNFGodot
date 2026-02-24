extends "NoteSolid.gd"

static var keyCount: int = 4
static var chess_rect_size: Vector2 = Vector2(30,30)

var chart_data: Dictionary

var section_parent: Array
var note_section: int
var sustain: SolidNode2D

var strumTime: float
var gfNote: bool: set = set_gf_note
var noteType: String: set = set_note_type

var interator: Control = Control.new()

func _init(data: Dictionary = chart_data):
	super(); 
	
	noteData = int(data.get("d",0)) % Conductor.songData.keyCount
	strumTime = data.get("t",0.0)
	chart_data = data;
	gfNote = data.get("g", false)
	noteType = data.get("k", '')
	sustainLength = data.get("l",0.0)
	
	image.add_child(interator)
	image.item_rect_changed.connect(_update_note_scale)

func _get_pivot() -> Vector2: return chess_rect_size * 0.5
func _update_note_scale():
	var size = image.region_rect.size
	var div = chess_rect_size / size
	var div_max = div[div.max_axis_index()]
	image.scale = Vector2(div_max,div_max)
	interator.size = size
	interator.pivot_offset = size*0.5

#region Setters
func _update_pivot() -> void: 
	super(); interator.position = (interator.size.rotated(-rotation) - interator.size) * 0.5

func _set_chart_value(val: Variant, key: String):
	if !val: chart_data.erase(key)
	else: chart_data[key] = val

func set_note_data(_data: int) -> void: chart_data.d = _data; super(_data); 
func set_note_type(type: String): noteType = type; _set_chart_value(type,"k")
func set_gf_note(gf: bool): gfNote = gf; _set_chart_value(gf,"g"); image.modulate.r = 10.0 if gf else 1.0
func _set_sustain_length(length: float) -> void:
	super(length)
	_set_chart_value(sustainLength,"l")
	if sustainLength: _create_sustain(); return
	if sustain: sustain.queue_free()

func _update_note_from_style(): super(); noteScale = 1.0; _update_note_scale()


func _update_sustain():
	sustain.size.x = 6.0;
	sustain.position = Vector2((chess_rect_size.x-sustain.size.x) * 0.5, chess_rect_size.y) 
	sustain.size.y = (sustainLength / Conductor.bpm_data.stepCrochet) * (chess_rect_size.y)

func _create_sustain():
	if !sustain: sustain = SolidNode2D.new(); sustain.size.x = chess_rect_size.x * 0.25; add_child(sustain)
	_update_sustain()
