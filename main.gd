extends Node3D

@export var resolution_scale : int = 2
@export var shader_type : CShader.SHADER_TYPE = CShader.SHADER_TYPE.INVERT
@export var noise : NOISE_TYPE = NOISE_TYPE.BINARY

@onready var rod : MeshInstance3D = $RodMesh
@onready var cube : Node3D = $Cube

@onready var character : CharacterBody3D = $Character
@onready var debugPanel : PanelContainer = $UserInterface/Overlay/DebugPanel
@onready var shaderMenu : PanelContainer = $UserInterface/Overlay/ShaderMenu
@onready var charView : SubViewport = $UserInterface/HeadcamVPContainer/HeadcamViewport
@onready var charCam : Camera3D = $Character.CAMERA
@onready var renderViewContainer : SubViewportContainer = $UserInterface/RenderVPContainer
@onready var renderView : SubViewport = $UserInterface/RenderVPContainer/RenderViewport
@onready var spawnPos : Vector3 = $Character.position

@onready var noiseRect : Sprite2D = $UserInterface/RenderVPContainer/RenderViewport/BG
@onready var shaderRect : Sprite2D = $UserInterface/RenderVPContainer/RenderViewport/OverlayFull

@onready var shader : CShader = CShader.new(shader_type)

var time_elapsed = 0.0
var frame_time = 2.0
var snap = 0
var paused = false
var occluding = true
#var using_noise = true  # If the shader being used relies on the noise texture
#var shader_name
var noise_name

var init_width = 1152
var init_height = 648

#var stage_tex
#var last_stage_tex

var objects = ["fish", "lily pad", "cat tails", "cube"]
var to_find = ""
var last_click = "none"

#enum SHADER_TYPE {
	#INVERT, BINARY, INCREMENTAL,
	#FADE, FADE_FULL_COLOR, OPTIC_FLOW,
	#OPTIC_FLOW_ALL, TEST, NONE
#}
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
	
	if not shader.uses_noise:
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
			if shader.uses_noise:
				noiseRect.show()
	
	if Input.is_action_just_pressed("toggle_menu"):
		shaderMenu.visible = !shaderMenu.visible
	
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
	## Create/set shader to a CShader instance based on current shader_type
	shader.set_shader(shader_type)
	print("using shader: ", shader.title)
	debugPanel.add_property("Shader", shader.title, Debug.SHADER)
	
	if shader_type == CShader.SHADER_TYPE.NONE:
		renderViewContainer.hide()
	else:
		shaderRect.material = shader.material
		if shader.menu:
			var menu = shader.menu.instantiate()
			shaderMenu.add_child(menu)


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
	if shader.uses_noise:
		noiseRect.show()
		# Maybe set last_frame param to full black in an else here? vvvv
	#else:
		#await RenderingServer.frame_pre_draw
		#RenderingServer.global_shader_parameter_set("last_frame", ImageTexture.new())

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
	if event.is_action("click"):
	#if Input.is_action_just_pressed("click"):
		object_click('cube')

func _on_fish_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	#print('fish event')
	if Input.is_action_just_pressed("click"):
		object_click('fish')

func _on_cattails_static_body_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	#print('cat tails event')
	if Input.is_action_just_pressed("click"):
		object_click('cat tails')

func _on_lilypad_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	#print('lily pad event')
	print(event)
	if event is InputEventMouseButton:
	#if Input.is_action_just_pressed("click"):
		object_click('lily pad')

## Temp shader param signals
func _on_res_scale_spin_box_value_changed(value: float) -> void:
	shader.material.set_shader_parameter("resScale", value)

func _on_diff_thresh_spin_box_value_changed(value: float) -> void:
	shader.material.set_shader_parameter("DIFF_THRESHOLD", value)

func _on_neigh_size_spin_box_value_changed(value: float) -> void:
	shader.material.set_shader_parameter("winSize", value)
