extends Node3D

@onready var overlay : TextureRect = $RenderVPContainer/RenderViewport/OverlayRect
@onready var rod : MeshInstance3D = $StagingVPContainer/StagingViewport/RodMesh

@onready var stagingView : SubViewport = $StagingVPContainer/StagingViewport
@onready var renderView : SubViewport = $RenderVPContainer/RenderViewport

var time_elapsed = 0.0
var prev_frame_texture

# Wisdom: https://forum.gamemaker.io/index.php?threads/solved-issue-trying-to-imitate-visual-effect-with-shaders-and-surfaces.109391/

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$RenderVPContainer/RenderViewport/RenderCamera.make_current()
	#$StagingVPContainer/StagingViewport/StagingCamera.make_current()
	
	# Initialize RNG
	randomize()
	
	# Create the image texture and image to hold each frame
	prev_frame_texture = ImageTexture.new()
	var width = $StagingVPContainer.get_viewport_rect().size.x
	var height = $StagingVPContainer.get_viewport_rect().size.y
	print(width, "x", height)
	var noise_img = Image.create(width, height, false, Image.FORMAT_RGB8)
	
	# Randomly populate first frame with black/white pixels
	for x in range(width):
		for y in range(height):
			if randi() % 2 == 0:
				noise_img.set_pixel(x, y, Color.WHITE)
			else:
				noise_img.set_pixel(x, y, Color.BLACK)
	
	# Assign image to texture
	prev_frame_texture = ImageTexture.create_from_image(noise_img)
	RenderingServer.global_shader_parameter_set("noise", prev_frame_texture)
	RenderingServer.global_shader_parameter_set("last_frame", prev_frame_texture)
	overlay.texture = prev_frame_texture
	
	#print("Pixel (300, 300): ", noise_img.get_pixel(300, 300))
	#print("Overlay texture size: ", overlay.texture.get_size())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_select"):
		Engine.time_scale = 0.01
	
	# Oscillate the rod
	rod.position.x = 3 * cos(time_elapsed)
	time_elapsed += delta
	
	RenderingServer.global_shader_parameter_set(
		"last_frame",
		stagingView.get_texture().get_image()
	)
	
