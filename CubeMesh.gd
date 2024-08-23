extends MeshInstance3D

var spin_axis : Vector3 = Vector3.UP


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#match randi()%3:
		#0:
			#spin_axis = spin_axis.rotated(
				#Vector3.UP,
				#randf_range(0, PI/4)
			#)
		#1:
			#spin_axis = spin_axis.rotated(
				#Vector3.RIGHT,
				#randf_range(0, PI/4)
			#)
		#2:
			#spin_axis = spin_axis.rotated(
				#Vector3.FORWARD,
				#randf_range(0, PI/4)
			#)
			#
	#rotate(spin_axis, delta*PI/8)
	#spin_axis = spin_axis.rotated()
	
	#rotate(Vector3.UP, delta*PI/(randi()%8+1))
	#rotate(Vector3.RIGHT, delta*PI/(randi()%8+1))
	#rotate(Vector3.FORWARD, delta*PI/(randi()%8+1))
	
	rotate(Vector3.UP, delta*PI/8)
