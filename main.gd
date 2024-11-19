extends Node3D

@export var resolution_scale : int = 2
@export var shader : SHADER_TYPE = SHADER_TYPE.INVERT
@export var noise : NOISE_TYPE = NOISE_TYPE.BINARY

@onready var rod : MeshInstance3D = $RodMesh
@onready var cube : Node3D = $Cube

@onready var character : CharacterBody3D = $Character
@onready var debugPanel : PanelContainer = $UserInterface/Overlay/DebugPanel
@onready var charView : SubViewport = $UserInterface/HeadcamVPContainer/HeadcamViewport
@onready var charCam : Camera3D = $Character.CAMERA
@onready var renderViewContainer : SubViewportContainer = $UserInterface/RenderVPContainer
@onready var renderView : SubViewport = $UserInterface/RenderVPContainer/RenderViewport
@onready var spawnPos : Vector3 = $Character.position

@onready var noiseRect : Sprite2D = $UserInterface/RenderVPContainer/RenderViewport/BG
@onready var shaderRect : Sprite2D = $UserInterface/RenderVPContainer/RenderViewport/OverlayFull

var time_elapsed = 0.0
var frame_time = 2.0
var snap = 0
var paused = false
var occluding = true
var using_noise = true  # If the shader being used relies on the noise texture
var shader_name
var noise_name

var init_width = 1152
var init_height = 648

#var stage_tex
#var last_stage_tex

var objects = ["fish", "lily pad", "cat tails", "cube"]
var to_find = ""
var last_click = "none"

enum SHADER_TYPE {
	INVERT, BINARY, INCREMENTAL,
	FADE, FADE_FULL_COLOR, OPTIC_FLOW,
	OPTIC_FLOW_ALL, TEST, NONE
}
enum NOISE_TYPE {
	BINARY, LINEAR, FULL_COLOR,
	PERLIN, FILL_BLACK, FILL_WHITE
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## Apply resolution scale factor
	set_res_scale()
	
	## Set shader and noise from export vars
	set_shader()
	set_noise()
	
	## Set the current_frame shader param to the texture of the viewport assigned
	## to the character camera
	RenderingServer.global_shader_parameter_set("current_frame", charView.get_texture())
	#RenderingServer.global_shader_parameter_set("last_frame", charView.get_texture())
	#RenderingServer.global_shader_parameter_set("last_render", renderView.get_texture())
	
	## Initialize RNG
	randomize()
	## Set initial object to find
	new_object()
	
	if not using_noise:
		noiseRect.hide()
	
	## Connect the frame_post_draw signal to call post_draw() after each frame is drawn
	RenderingServer.connect("frame_post_draw", post_draw)
	
	Window.new()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	## Add FPS to debug panel
	#debugPanel.add_property("FPS", Performance.get_monitor(Performance.TIME_FPS), 0)
	
	## Toggle debug menu
	if Input.is_action_just_pressed("toggle_debug"):
		debugPanel.visible = !debugPanel.visible
	
	## Toggle pause state
	if Input.is_action_just_pressed("pause"):
		if paused:
			paused = false
		else:
			paused = true
	
	## Show/hide shader overlay
	if Input.is_action_just_pressed("shader_toggle"):
		if renderViewContainer.visible:
			renderViewContainer.hide()
		else:
			renderViewContainer.show()
			if using_noise:
				noiseRect.show()
	
	## Increase/decrease resolution scale
	if Input.is_action_just_released("res_increase"):
		var last_scale = resolution_scale
		resolution_scale = clamp(resolution_scale+1, 1, 8)
		set_res_scale()
		if resolution_scale != last_scale:
			print("resolution scale: ", resolution_scale)
	elif Input.is_action_just_released("res_decrease"):
		var last_scale = resolution_scale
		resolution_scale = clamp(resolution_scale-1, 1, 8)
		set_res_scale()
		if resolution_scale != last_scale:
			print("resolution scale: ", resolution_scale)
	
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


#func pre_draw():
	#print('draw')
	#get_snapshots()

func post_draw():
	## After frame draw: get a snapshot of the current stage view and apply the
	## shader parameter so shaders can read from the previous frame
	var snap = charView.get_texture().get_image()
	RenderingServer.global_shader_parameter_set("last_frame", ImageTexture.create_from_image(snap))
	#RenderingServer.global_shader_parameter_set("last_frame", charView.get_texture().get_image())
	
	if noiseRect.visible:
		noiseRect.hide()


func set_shader():
	## Set shader from export var
	match shader:
		SHADER_TYPE.INVERT:
			shader_name = "Invert"
			shaderRect.material = load("res://materials/pov.tres")
		SHADER_TYPE.BINARY:
			shader_name = "Binary"
			shaderRect.material = load("res://materials/pov_binary.tres")
			using_noise = false
		SHADER_TYPE.INCREMENTAL:
			shader_name = "Incremental"
			shaderRect.material = load("res://materials/pov_incremental.tres")
		SHADER_TYPE.FADE:
			shader_name = "Fade"
			shaderRect.material = load("res://materials/pov_fade.tres")
			using_noise = false
		SHADER_TYPE.FADE_FULL_COLOR:
			shader_name = "Fade (full color)"
			shaderRect.material = load("res://materials/pov_fade_fullcolor.tres")
			using_noise = false
		SHADER_TYPE.OPTIC_FLOW:
			shader_name = "Optic flow (constrained)"
			shaderRect.material = load("res://materials/optic_flow.tres")
			using_noise = false
		SHADER_TYPE.OPTIC_FLOW_ALL:
			shader_name = "Optic flow (every pixel)"
			shaderRect.material = load("res://materials/optic_flow_all.tres")
			using_noise = false
		SHADER_TYPE.TEST:
			var testMaterial:ShaderMaterial = load("res://materials/test.tres")
			shader_name = testMaterial.shader.resource_path
			shaderRect.material = testMaterial
		SHADER_TYPE.NONE:
			shader_name = "None"
			print("using shader: none")
			renderViewContainer.hide()
	print("using shader: ", shader_name)
	debugPanel.add_property("Shader", shader_name, Debug.SHADER)


func set_noise():
	## Set noise from export var
	noiseRect.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	match noise:
		NOISE_TYPE.BINARY:
			noise_name = "Black or white"
			noiseRect.texture = load("res://images/binary_noise-1152x648.png")
		NOISE_TYPE.LINEAR:
			noise_name = "Grayscale"
			noiseRect.texture = load("res://images/linear_noise-1152x648.png")
		NOISE_TYPE.FULL_COLOR:
			noise_name = "Full spectrum"
			noiseRect.texture = load("res://images/rand_img_full-1152x648.png")
		NOISE_TYPE.PERLIN:
			noise_name = "Perlin"
			noiseRect.texture = load("res://images/perlin_s21-c4-l5-a0.4.png")
		NOISE_TYPE.FILL_BLACK:
			noise_name = "Fill (black)"
			noiseRect.texture = load("res://images/white-1152x648.png")
			noiseRect.self_modulate = Color(0.0, 0.0, 0.0)
		NOISE_TYPE.FILL_WHITE:
			noise_name = "Fill (white)"
			noiseRect.texture = load("res://images/white-1152x648.png")
	print("using noise: ", noise_name)
	debugPanel.add_property("Noise", noise_name, Debug.NOISE)


func set_res_scale():
	## Set resolution scale to {1/resolution_scale} of full resolution (1152 x 648)
	get_tree().root.content_scale_factor = resolution_scale
	
	var scale_width = init_width / resolution_scale
	var scale_height = init_height / resolution_scale
	
	## Scale and resize viewports and UI
	# Investigate built-in scaling/resizing options for this....
	renderView.size.x = scale_width
	renderView.size.y = scale_height
	charView.size.x = scale_width
	charView.size.y = scale_height
	$Character.res_scale = resolution_scale
	#$UserInterface/RenderVPContainer/RenderViewport/OverlayVignette.size = charView.size
	$UserInterface/Overlay.pivot_offset.x = renderView.size.x / 2.0
	$UserInterface/Overlay.pivot_offset.y = renderView.size.y / 2.0
	$UserInterface/Overlay.scale = Vector2(1.0 / resolution_scale, 1.0 / resolution_scale)
	
	## Update debug panel
	var res_str
	if resolution_scale == 1:
		res_str = "1"
	else:
		res_str = "1/" + str(resolution_scale)
	debugPanel.add_property("Resolution scale", res_str, Debug.RES_SCALE)
	debugPanel.add_property("Resolution", str(scale_width) + " x " + str(scale_height), Debug.RES)
	
	renderView.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	if using_noise:
		noiseRect.show()
		# Maybe set last_frame param to full black in an else here? vvvv
	#else:
		#await RenderingServer.frame_pre_draw
		#RenderingServer.global_shader_parameter_set("last_frame", ImageTexture.new())


#func get_snapshots():
	## Take a snapshot of the current 'stage' frame, assign to global shader param
	#var staging_snapshot = charView.get_texture().get_image()
	#var staging_snapshot = get_tree().root.get_viewport().get_texture().get_image()
	## Store last and second-to-last stage textures
	#last_stage_tex = stage_tex
	#stage_tex = ImageTexture.create_from_image(staging_snapshot)
	#RenderingServer.global_shader_parameter_set(
		#"last_stage",
		#stage_tex
	#)
	#RenderingServer.global_shader_parameter_set(
		#"second_last_stage",
		#last_stage_tex
	#)
	#
	## Take a snapshot of the current 'render' frame, assign to global shader param
	#var render_snapshot = renderView.get_texture().get_image()
	#var render_tex = ImageTexture.create_from_image(render_snapshot)
	#RenderingServer.global_shader_parameter_set(
		#"last_render",
		#render_tex
	#)
	#
	#if frame_time >= 2.0:
		#print('Snapshot ' + str(snap))
		#render_snapshot.save_png("./out/snap-" + str(snap) + "-R.png")
		#staging_snapshot.save_png("./out/snap-" + str(snap) + "-S.png")
		#frame_time = 0.0
		#snap += 1
	#frame_time += delta


func new_object():
	var r = randi() % len(objects)
	while objects[r] == to_find:
		r = randi() % len(objects)
	
	to_find = objects[r]
	print('setting to_find: ' + to_find)
	update_label()


func update_label():
	$UserInterface/Overlay/TextBG/Label.text = to_find + "\n" + last_click


func object_click(id):
	print(id + ' clicked')
	last_click = id
	if id == to_find:
		$UserInterface/Overlay/Match.display()
		new_object()
	else:
		update_label()


func _on_cube_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if Input.is_action_just_pressed("click"):
		object_click('cube')


func _on_fish_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if Input.is_action_just_pressed("click"):
		object_click('fish')


func _on_cattails_static_body_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if Input.is_action_just_pressed("click"):
		object_click('cat tails')


func _on_lilypad_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if Input.is_action_just_pressed("click"):
		object_click('lily pad')
