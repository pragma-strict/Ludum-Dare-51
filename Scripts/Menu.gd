extends Spatial


func _ready():
	get_tree().paused = false
	yield(get_tree().create_timer(0.8), "timeout")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _input(_event):
	if (Input.is_key_pressed(KEY_ESCAPE)):
		get_tree().quit()
	if (Input.is_action_just_pressed("interact")):
		var _result = get_tree().change_scene("res://Scenes/Main.tscn")
