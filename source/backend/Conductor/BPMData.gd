@icon("res://icons/BPMChanges.svg")
class_name BPMData extends Resource

var time: float
var section: float
var beat: float
var step: float
@export var bpm: float: set = set_bpm
var crochet: float
var stepCrochet: float
var stepCrochetMs: float
var sectionCrochet: float

func set_bpm(b: float): bpm = b; _update_crochets(); 

func _update_crochets():
	if !bpm:
		crochet = 0.0
		stepCrochet = 0.0
		stepCrochetMs = 0.0
		sectionCrochet = 0.0
	else:
		crochet = get_crochet(bpm)
		stepCrochet = crochet * 0.25
		stepCrochetMs = stepCrochet * 0.001
		sectionCrochet = crochet * 4.0
	changed.emit()

func clear():
	time = 0.0
	section = 0.0
	beat = 0.0
	step = 0.0
	bpm = 0.0

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"beat",&"step",&"time",&"section",&"bpm",\
		&"crochet",&"stepCrochet",&"sectionCrochet",&"stepCrochetMs": 
			property.usage = PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR
		
static func get_crochet(_bpm: float) -> float: return 60000 / _bpm
static func get_step_crochet(_bpm: float) -> float: return 15000.0/_bpm
static func get_section_crochet(_bpm: float, section_beats: float = 4) -> float:  return (60000 / _bpm) * section_beats
