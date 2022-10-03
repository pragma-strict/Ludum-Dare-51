extends Node

class_name IntVector2

var x
var y

func _init(new_x:int, new_y:int):
	x = new_x
	y = new_y

func add(other:IntVector2):
	x += other.x
	y += other.y
	return self

func sub(other:IntVector2):
	x -= other.x
	y -= other.y
	return self

func print_vec():
	print("x: ", x, ", y: ", y)

func to_string():
	return (str("[x: ", x, ", y: ", y, "]"))

func to_vec3():
	return Vector3(x, 0, y)

func normalize():
	if(x > 0):
		x = 1
	elif(x < 0):
		x = -1
	if(y > 0):
		y = 1
	elif(y < 0):
		y = -1
	return self

#static func addTo(add_to:IntVector2, amount:IntVector2):
#	return IntVector2.new(add_to.x + amount.x, add_to.y + amount.y)
#
#static func subFrom(sub_from:IntVector2, amount:IntVector2):
#	return IntVector2.new(sub_from.x - amount.x, sub_from.y - amount.y)
