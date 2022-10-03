extends RayCast


var is_colliding = false

signal collide_begin(object)
signal collide_end(object)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if(is_colliding() and !is_colliding):
		is_colliding = true
		collide()
	elif(!is_colliding() and is_colliding):
		is_colliding = false
		stop_colliding()


func collide():
	emit_signal("collide_begin", get_collider())


func stop_colliding():
	emit_signal("collide_end", get_collider())
