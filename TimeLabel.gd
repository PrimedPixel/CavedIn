extends Label

var stopped: bool = false
var elapsed_time: float = 0

func _process(delta):
	if !stopped:
		elapsed_time += delta
	
	text = format_seconds(elapsed_time)


func format_seconds(time) -> String:
	var minutes = time / 60
	var seconds = fmod(time, 60)
	
	return "%02d:%02d" % [minutes, seconds]
