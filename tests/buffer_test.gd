extends Node2D

@onready var viewport: SubViewport = $SubViewportContainer/SubViewport

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#get_tree().root.get_viewport().clear
	RenderingServer.connect("frame_pre_draw", pre_draw)
	
	await RenderingServer.frame_post_draw
	
	$SubViewportContainer/SubViewport/CheckerRect.hide()
	$SubViewportContainer/SubViewport/MousePosRect.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func pre_draw():
	var pos = get_global_mouse_position()
	var shaderPos = Vector2(pos.x / 1152.0, pos.y / 648.0)
	#print(shaderPos)
	RenderingServer.global_shader_parameter_set("mouse_pos", shaderPos)
	
