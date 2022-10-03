extends RigidBody


func _ready():
	contact_monitor = true



func destroy():
	print("Projectile destroyed")
	queue_free()
