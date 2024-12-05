extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.current_animation = "Scene"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	## Rotate the fish each frame
	rotate_y(-0.18 * delta)
