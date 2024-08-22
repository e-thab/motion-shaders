extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate_x(delta*PI/2)
	rotate_y(delta*PI/2)
	rotate_z(delta*PI/2)
