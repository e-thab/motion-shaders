extends Node3D

@export var resolution_scale : int = 1

@onready var rod : MeshInstance3D = $RodMesh
@onready var cube : Node3D = $Cube

@onready var character : CharacterBody3D = $Character
@onready var charView : SubViewport = $Character/UserInterface/HeadcamVPContainer/HeadcamViewport
@onready var charCam : Camera3D = $Character.CAMERA
@onready var renderViewContainer : SubViewportContainer = $Character/UserInterface/RenderVPContainer
@onready var renderView : SubViewport = $Character/UserInterface/RenderVPContainer/RenderViewport
@onready var spawnPos : Vector3 = $Character.position

var time_elapsed = 0.0
var frame_time = 2.0
var snap = 0
var paused = false
var occluding = true

var init_width = 1152
var init_height = 648

var stage_tex
var last_stage_tex


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
	## Toggle pause state
	if Input.is_action_just_pressed("pause"):
		if paused:
			paused = false
		else:
			paused = true
	
	## Show/hide shader overlay
	if Input.is_action_just_pressed("overlay_toggle"):
		if renderViewContainer.visible:
			renderViewContainer.hide()
		else:
			renderViewContainer.show()
	
	## Increase/decrease resolution scale
	if Input.is_action_just_released("res_increase"):
		resolution_scale += 1
		print("resolution scale: ", resolution_scale)
		set_res_scale()
	elif Input.is_action_just_released("res_decrease"):
		resolution_scale = max(resolution_scale-1, 1)
		print("resolution scale: ", resolution_scale)
		set_res_scale()
	
	## Show/hide objects in 'fill' group based on toggle
	if Input.is_action_just_pressed("toggle_occlusion"):
		if occluding:
			occluding = false
			get_tree().call_group("fill", "hide")
			print("occlusion off")
		else:
			occluding = true
			get_tree().call_group("fill", "show")
			print("occlusion on")
	
	if !paused:
		## Oscillate the rod & rotate the cube
		rod.position.x = 3 * cos(time_elapsed*PI/6)
		time_elapsed += delta
		cube.rotate(Vector3.UP, delta*PI/4)
	
	## Respawn if char has fallen some distance
	if character.position.y < -50.0:
		character.position = spawnPos
	
	frame_time += delta
	get_snapshots()


func set_res_scale():
	get_tree().root.content_scale_factor = resolution_scale
	renderView.size.x = int(init_width / resolution_scale)
	renderView.size.y = int(init_height / resolution_scale)
	charView.size.x = int(init_width / resolution_scale)
	charView.size.y = int(init_height / resolution_scale)
	$Character.res_scale = resolution_scale
	$Character/UserInterface/RenderVPContainer/RenderViewport/OverlayVignette.size = charView.size
	
	#$Character/UserInterface/Overlay.size = renderView.size
	#$Character/UserInterface/Overlay.scale = Vector2(resolution_scale, resolution_scale)
	#$Character/UserInterface/Overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	#$Character/UserInterface/Overlay.set_anchor(SIDE_RIGHT, 1.0/resolution_scale)
	#$Character/UserInterface/Overlay.set_anchor(SIDE_BOTTOM, 1.0/resolution_scale)
	#$Character/UserInterface/Overlay.scale = Vector2(1.0/resolution_scale, 1.0/resolution_scale)
	#$Character/UserInterface/Overlay/Reticle.scale = Vector2(1.0/resolution_scale, 1.0/resolution_scale)
	#$Character/UserInterface/Overlay/Reticle.position = Vector2(renderView.size.x/2.0, renderView.size.y/2.0)


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
