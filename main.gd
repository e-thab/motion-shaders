extends Node3D

@export var resolution_scale : float = 1.0

@onready var rod : MeshInstance3D = $RodMesh
@onready var stagingView : SubViewport = $StagingVPContainer/StagingViewport
@onready var renderView : SubViewport = $RenderVPContainer/RenderViewport

var time_elapsed = 0.0
var frame_time = 2.0
var snap = 0
var paused = false

var stage_tex
var last_stage_tex

# Wisdom: https://forum.gamemaker.io/index.php?threads/solved-issue-trying-to-imitate-visual-effect-with-shaders-and-surfaces.109391/

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize RNG
	#randomize()
	
	## Apply resolution scale factor
	get_tree().root.content_scale_factor = resolution_scale
	renderView.size.x = int(stagingView.size.x / resolution_scale)
	renderView.size.y = int(stagingView.size.y / resolution_scale)
	stagingView.size.x = int(stagingView.size.x / resolution_scale)
	stagingView.size.y = int(stagingView.size.y / resolution_scale)
	
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
	
	if Input.is_action_just_pressed("render_swap"):
		if $RenderVPContainer.visible:
			$RenderVPContainer.hide()
		else:
			$RenderVPContainer.show()
	
	## Oscillate the rod
	rod.position.x = 3 * cos(time_elapsed*PI/6)
	time_elapsed += delta
	
	#frame_time += delta
	get_snapshots()


func get_snapshots():
	## Take a snapshot of the current 'stage' frame, assign to global shader param
	var staging_snapshot = stagingView.get_texture().get_image()
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
