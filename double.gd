extends Node3D

@onready var overlay : TextureRect = $RenderVPContainer/RenderViewport/OverlayRect
@onready var rod : MeshInstance3D = $RodMesh

@onready var stagingView : SubViewport = $StagingVPContainer/StagingViewport
@onready var renderView : SubViewport = $RenderVPContainer/RenderViewport

var time_elapsed = 0.0
var frame_time = 2.0
var snap = 0
var paused = false
var noise_texture

var stage_tex
var last_stage_tex

# Wisdom: https://forum.gamemaker.io/index.php?threads/solved-issue-trying-to-imitate-visual-effect-with-shaders-and-surfaces.109391/

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize RNG
	randomize()
	
	# Generate noise texture
	noise_texture = ImageTexture.new()
	var width = stagingView.get_visible_rect().size.x
	var height = stagingView.get_visible_rect().size.y
	print(width, "x", height)
	var noise_img = Image.create(width, height, false, Image.FORMAT_RGB8)
	
	# Randomly populate texture with black/white pixels (noise)
	for x in range(width):
		for y in range(height):
			if randi() % 2 == 0:
				noise_img.set_pixel(x, y, Color.WHITE)
			else:
				noise_img.set_pixel(x, y, Color.BLACK)
	
	## Assign image to texture
	#noise_texture = ImageTexture.create_from_image(noise_img)
	#RenderingServer.global_shader_parameter_set("noise", noise_texture)
	#RenderingServer.global_shader_parameter_set(
		#"last_render",
		#noise_texture
	#)
	#overlay.texture = noise_texture
	#noise_img.save_png("./out/noise.png")
	
	#print("Pixel (300, 300): ", noise_img.get_pixel(300, 300))
	#print("Overlay texture size: ", overlay.texture.get_size())
	get_snapshots()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if paused:
			paused = false
			Engine.time_scale = 1.0
		else:
			paused = true
			Engine.time_scale = 0.0
		RenderingServer.global_shader_parameter_set("paused", paused)
	
	if Input.is_action_just_pressed("render_swap"):
		if renderView.visible:
			renderView.hide()
		else:
			renderView.show()
	
	## Oscillate the rod
	rod.position.x = 3 * cos(time_elapsed*PI/6)
	time_elapsed += delta
	frame_time += delta
	
	#if time_elapsed < 0.5:
		#return
	get_snapshots()


func get_snapshots():
	## Take a snapshot of the current 'stage' frame, assign to global shader param
	last_stage_tex = stage_tex
	var staging_snapshot = stagingView.get_texture().get_image()
	stage_tex = ImageTexture.create_from_image(staging_snapshot)
	RenderingServer.global_shader_parameter_set(
		"last_stage",
		stage_tex
	)
	RenderingServer.global_shader_parameter_set(
		"second_last_stage",
		last_stage_tex
	)
	
	## Take a snapshot of the current 'render' frame, assign to global shader param
	var render_snapshot = renderView.get_texture().get_image()
	var render_tex = ImageTexture.create_from_image(render_snapshot)
	RenderingServer.global_shader_parameter_set(
		"last_render",
		render_tex
	)
	
	if frame_time >= 2.0:
		print('Snapshot ' + str(snap))
		render_snapshot.save_png("./out/snap-" + str(snap) + "-R.png")
		staging_snapshot.save_png("./out/snap-" + str(snap) + "-S.png")
		frame_time = 0.0
		snap += 1
