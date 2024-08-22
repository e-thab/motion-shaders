extends Node3D

@onready var rod : MeshInstance3D = $RodMesh
var time_elapsed = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rod.position.x = 3 * cos(time_elapsed)
	time_elapsed += delta
