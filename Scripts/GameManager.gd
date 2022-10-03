extends Node

export(Array, float) var beep_delays
export(AudioStreamSample) var explosion_sample
export(AudioStreamSample) var self_destruct_mode_sample
export(AudioStreamSample) var escape_sample

onready var timer_audio = $"CountdownTimer"
onready var speech_audio = $"Speech"
onready var game_anims = $"Player/AnimationPlayer"

const END_GAME_MENU_DELAY = 5.0
const TIMER_INITIAL_TIME = 10
const ENABLE_INTRO = true

var is_mouse_captured = false
var screen_mode_lock = false
var screen_brightness = 0.01 # Cannot be 0

var seconds_remaining
var turret_list:Array
var pad_list:Array

var fullscreen_timer:Timer
var self_destruct_timer:Timer
var beep_timer:Timer

signal timer_updated(new_time)
signal self_destruct


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	is_mouse_captured = true
	start_game()


func start_game():
	$"Player/PlayerCam".environment.adjustment_brightness = 0.01
	if(ENABLE_INTRO):
		yield(get_tree().create_timer(1), "timeout")
		$"Player".enable_input = false
		speech_audio.stream = self_destruct_mode_sample
		speech_audio.play()
		yield(get_tree().create_timer(3), "timeout")
		yield(get_tree().create_timer(1), "timeout")
		$"Music".play()
		$"Player".enable_input = true
	game_anims.play("EnvironmentFadeIn")
	create_beep_timer()
	create_self_destruct_timer()
	start_sd_timer()
	beep_timer.start()


func _input(_event):
#	debug_input(_event)
	if (Input.is_key_pressed(KEY_ESCAPE)):
		var _result = get_tree().change_scene("res://Scenes/Menu.tscn")
	

func debug_input(event):
	if (event is InputEventMouseButton):
		if(event.is_action_pressed("mouse_right")):
			is_mouse_captured = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			is_mouse_captured = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	if (Input.is_action_pressed("ui_fullscreen")):
		toggle_fullscreen()
	
	if (Input.is_key_pressed(KEY_ESCAPE)):
		get_tree().quit()


func toggle_fullscreen():
	if(!screen_mode_lock):
		OS.window_fullscreen = !OS.window_fullscreen
		screen_mode_lock = true
		yield(get_tree().create_timer(1.0), "timeout")
		screen_mode_lock = false


func create_beep_timer():
	beep_timer = Timer.new()
	add_child(beep_timer)
	beep_timer.set_wait_time(beep_delays[10])
	var _result = beep_timer.connect("timeout", self, "beep")


func create_self_destruct_timer():
	seconds_remaining = TIMER_INITIAL_TIME
	self_destruct_timer = Timer.new()
	add_child(self_destruct_timer)
	var _result = self_destruct_timer.connect("timeout", self, "tick_second")


func start_sd_timer():
	emit_signal("timer_updated", seconds_remaining)
	self_destruct_timer.start(1.0)


func tick_second():
	seconds_remaining -= 1
	if(seconds_remaining < 0):
		self_destruct()
		emit_signal("self_destruct")
		self_destruct_timer.stop()
	else:
		self_destruct_timer.start(1.0)
		emit_signal("timer_updated", seconds_remaining)


func _self_destruct_timer_reset():
	seconds_remaining = TIMER_INITIAL_TIME
	self_destruct_timer.stop()
	start_sd_timer()


func register_turret(turret:Node):
	turret_list.append(turret)


func remove_turret(turret:Node):
	turret_list.erase(turret)


func register_pad(pad:Node):
	pad_list.append(pad)


func remove_pad(pad:Node):
	pad_list.erase(pad)


func beep():
	if(seconds_remaining >= 0 and seconds_remaining < beep_delays.size()):
		timer_audio.play()
		beep_timer.set_wait_time(beep_delays[seconds_remaining])
		beep_timer.start()


func end_game():
	beep_timer.stop()
	get_tree().paused = true
	yield(get_tree().create_timer(END_GAME_MENU_DELAY), "timeout")
	var _result = get_tree().change_scene("res://Scenes/Menu.tscn")


func self_destruct():
	$"Player/PlayerCam".environment.adjustment_brightness = 0.01
	timer_audio.stream = explosion_sample
	timer_audio.play()
	end_game()
	

func win(_body):
	end_game()
