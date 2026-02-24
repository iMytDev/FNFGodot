@icon("res://icons/BPMChanges.svg")
class_name BeatsReduced extends Resource
@export var time: float
@export var section: float
@export var time_offset: float
@export var cutback: int:
	set(val): cutback = val; changed.emit()
