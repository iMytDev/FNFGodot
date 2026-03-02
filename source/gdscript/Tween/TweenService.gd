@tool
extends Node
const transitions = {
	'sine': Tween.TRANS_SINE,
	'quint': Tween.TRANS_QUINT,
	'quart': Tween.TRANS_QUART,
	'quad': Tween.TRANS_QUAD,
	'expo': Tween.TRANS_EXPO,
	'elastic': Tween.TRANS_ELASTIC,
	'cubic': Tween.TRANS_CUBIC,
	'circ': Tween.TRANS_CIRC,
	'bounce': Tween.TRANS_BOUNCE,
	'back': Tween.TRANS_BACK,
	'spring': Tween.TRANS_SPRING,
	'smoothstep': Tween.TRANS_SINE,
}

const easings = {
	'in': Tween.EASE_IN,
	'out': Tween.EASE_OUT,
	'inout': Tween.EASE_IN_OUT,
	'outin': Tween.EASE_OUT_IN
}

static func detect_trans(trans: String, default: Tween.TransitionType = Tween.TRANS_LINEAR) -> Tween.TransitionType:
	trans = trans.to_lower()
	for keys in transitions: if trans.begins_with(keys): return transitions[keys]
	return default

static func detect_ease(easing: String, default: Tween.EaseType = Tween.EASE_OUT) -> Tween.EaseType:
	easing = easing.to_lower()
	for tweenEase in easings: if easing.ends_with(tweenEase):return easings[tweenEase]
	return default

static func get_tween_presets() -> PackedStringArray:
	var tweens: PackedStringArray
	for t in transitions: for e in easings: tweens.append(t+e)
	return tweens

var tweens_to_update: Array[RefCounted]

func create_object_tween(object: Object,properties: Dictionary, time: float = 1.0, easing: String = &'') -> FunkinTweenerObject:
	if !object: return null
	var new_tween = FunkinTweenerObject.new(object,time,detect_trans(easing),detect_ease(easing))
	for property in properties: new_tween.tween_property(property,properties[property])
	tweens_to_update.append(new_tween)
	return new_tween


func create_tween_method(method: Callable, from: Variant, to: Variant, time: float = 1.0, ease: String = &'') -> FunkinTweenerMethod:
	var tween_method = FunkinTweenerMethod.new(method,from,to,time,detect_trans(ease),detect_ease(ease))
	tweens_to_update.append(tween_method)
	return tween_method

func _process(delta: float) -> void:
	if !tweens_to_update: return
	var index = tweens_to_update.size()
	while index:
		index -= 1
		var tween = tweens_to_update[index]
		if !tween.is_playing: tweens_to_update.remove_at(index); continue
		tween._process(delta)
