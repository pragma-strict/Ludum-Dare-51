extends Spatial

signal pressed

export(AudioStreamSample) var button_down_sample
export(AudioStreamSample) var button_up_sample
export(AudioStreamSample) var button_ding_sample

onready var audio = $"Audio"

const BUTTON_DELAY = 0.4
const DING_DELAY = 0.1
var is_pressed:bool = false

func _button_area_entered(_body):
	press()


func press():
	if(!is_pressed):
		is_pressed = true
		emit_signal("pressed")
		$"button".translate(Vector3(0, 0, -0.18))
		audio.stream = button_down_sample
		audio.play()
		yield(get_tree().create_timer(BUTTON_DELAY), "timeout")
		unpress()


func unpress():
	if(is_pressed):
		is_pressed = false
		$"button".translate(Vector3(0, 0, 0.18))
		audio.stream = button_up_sample
		audio.play()
		yield(get_tree().create_timer(DING_DELAY), "timeout")
		audio.stream = button_ding_sample
		audio.play()
