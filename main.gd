extends Node3D

@export var resolution_scale : float = 1.0

@onready var rod : MeshInstance3D = $RodMesh
@onready var charView : SubViewport = $Character/UserInterface/HeadcamVPContainer/HeadcamViewport
@onready var renderViewContainer : SubViewportContainer = $Character/UserInterface/RenderVPContainer
@onready var renderView : SubViewport = $Character/UserInterface/RenderVPContainer/RenderViewport

#@onready var stagingCam : Camera3D = $StagingVPContainer/StagingViewport/StagingCamera
@onready var charCam : Camera3D = $Character.CAMERA

var time_elapsed = 0.0
var frame_time = 2.0
var snap = 0
var paused = false

var init_width = 1152
var init_height = 648

var stage_tex
var last_stage_tex

# Wisdom: https://forum.gamemaker.io/index.php?threads/solved-issue-trying-to-imitate-visual-effect-with-shaders-and-surfaces.109391/

func _init():
	RenderingServer.set_debug_generate_wireframes(true)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## Initialize RNG
	#randomize()
	## Apply resolution scale factor
	set_res_scale()
	## Take initial render snapshots
	get_snapshots()
	charCam.make_current()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if paused:
			paused = false
			Engine.time_scale = 1.0
		else:
			paused = true
			Engine.time_scale = 0.0
	
	if Input.is_action_just_pressed("overlay_toggle"):
		if renderViewContainer.visible:
			renderViewContainer.hide()
		else:
			renderViewContainer.show()
	
	if Input.is_action_just_pressed("wire_toggle"):
		charView.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	
	if Input.is_action_just_released("res_increase"):
		resolution_scale += 1
		print(resolution_scale)
		set_res_scale()
	elif Input.is_action_just_released("res_decrease"):
		resolution_scale = max(resolution_scale-1, 1)
		print(resolution_scale)
		set_res_scale()
	
	## Oscillate the rod
	rod.position.x = 3 * cos(time_elapsed*PI/6)
	time_elapsed += delta
	
	frame_time += delta
	get_snapshots()
	
	#stagingCam.position = charCam.position


func set_res_scale():
	get_tree().root.content_scale_factor = resolution_scale
	renderView.size.x = int(init_width / resolution_scale)
	renderView.size.y = int(init_height / resolution_scale)
	#stagingView.size.x = int(init_width / resolution_scale)
	#stagingView.size.y = int(init_height / resolution_scale)


func get_snapshots():
	## Take a snapshot of the current 'stage' frame, assign to global shader param
	var staging_snapshot = charView.get_texture().get_image()
	#var staging_snapshot = get_tree().root.get_viewport().get_texture().get_image()
	## Store last and second-to-last stage textures
	last_stage_tex = stage_tex
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
	
	#if frame_time >= 2.0:
		#print('Snapshot ' + str(snap))
		#render_snapshot.save_png("./out/snap-" + str(snap) + "-R.png")
		#staging_snapshot.save_png("./out/snap-" + str(snap) + "-S.png")
		#frame_time = 0.0
		#snap += 1
