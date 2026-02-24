class_name FunkinTimerServer extends FunkinInternal

static var timersPlaying: Dictionary[StringName,Timer] ##[b]Timers[/b] created using [method runTimer] function.
static func runTimer(tag: StringName, time: float, loops: int = 1) -> Timer: ##Runs a timer, return the [Timer] created.
	loops = maxi(loops,0)
	var timer = timersPlaying.get(tag)
	if !timer: return _create_timer(tag,time,loops)
	timer.set_meta(&"loops", loops)
	timer.start(time)
	return timer

static func cancelTimer(tag: StringName) -> void:
	var timer = timersPlaying.get(tag); if !timer: return
	timersPlaying.erase(tag)
	timer.queue_free()

static func _timer_completed(timer: Timer):
	var loops = timer.get(&"loops")
	var tag = timer.name
	if loops: 
		timer.start(timer.get_meta(&"time")); 
		timer.set_meta(&"loops",loops - 1)
	else: 
		timersPlaying.erase(tag); 
		timer.queue_free()
		
	FunkinGD.callOnScripts(&'onTimerCompleted', tag, loops)

static func _create_timer(tag: StringName, time: float, loops: int = 0) -> Timer:
	loops = maxi(loops,0)
	if !time: 
		while loops >= 0: FunkinGD.callOnScripts(&'onTimerCompleted', tag,loops); loops -= 1
		return
	var timer = Timer.new()
	timer.name = tag
	timer.set_meta(&"time", time)
	timer.set_meta(&"loops",loops)
	_add_game_node(timer)
	timersPlaying[tag] = timer
	timer.start(time)
	timer.timeout.connect(_timer_completed.bind(timer))
	return timer

static func clear(absolute: bool):
	if absolute: for i in timersPlaying.values(): if i: i[0].stop()
	timersPlaying.clear()
