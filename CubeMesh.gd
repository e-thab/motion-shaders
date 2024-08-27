extends MeshInstance3D

var last_mouse_pos : Vector2 = Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#rotate(Vector3.UP, delta*PI/4)
	pass

func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseMotion:
		var x_change = event.position.x - last_mouse_pos.x
		var y_change = event.position.y - last_mouse_pos.y
		
		rotate(Vector3.UP, x_change/128)
		rotate(Vector3.RIGHT, y_change/128)
		
		last_mouse_pos = event.position
