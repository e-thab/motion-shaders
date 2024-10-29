extends Node3D

@export var resolution_scale : int = 2
@export var shader : SHADER_TYPE
@export var noise : NOISE_TYPE

@onready var rod : MeshInstance3D = $RodMesh
@onready var cube : Node3D = $Cube

@onready var character : CharacterBody3D = $Character
@onready var charView : SubViewport = $Character/UserInterface/HeadcamVPContainer/HeadcamViewport
@onready var charCam : Camera3D = $Character.CAMERA
@onready var renderViewContainer : SubViewportContainer = $Character/UserInterface/RenderVPContainer
@onready var renderView : SubViewport = $Character/UserInterface/RenderVPContainer/RenderViewport
@onready var spawnPos : Vector3 = $Character.position

@onready var noiseRect : TextureRect = $Character/UserInterface/RenderVPContainer/RenderViewport/BG
@onready var shaderRect : TextureRect = $Character/UserInterface/RenderVPContainer/RenderViewport/OverlayFull

var time_elapsed = 0.0
var frame_time = 2.0
var snap = 0
var paused = false
var occluding = true

var init_width = 1152
var init_height = 648

var stage_tex
var last_stage_tex

var objects = ["fish", "lily pad", "cat tails", "cube"]
var to_find = ""
var last_click = "none"

var noise_img
var shader_mat
enum SHADER_TYPE {INVERT, BINARY, INCREMENTAL, FADE, FADE_FULL_COLOR}
enum NOISE_TYPE {BINARY, LINEAR, FULL_COLOR, PERLIN}


func _init():
	#RenderingServer.set_debug_generate_wireframes(true)
	# Match statement not working for some reason. Defaults to invert shader + binary noise
	# https://www.reddit.com/r/godot/comments/10epb3l/accessing_exported_properties_in_init/
	print("Shader should be: ", shader)
	print("Noise should be: ", noise)
	match shader:
		SHADER_TYPE.INVERT:
			print("loading invert shader")
			shader_mat = load("res://materials/pov.tres")
		SHADER_TYPE.BINARY:
			print("loading binary shader")
			shader_mat = load("res://shaders/pov_binary.tres")
		SHADER_TYPE.INCREMENTAL:
			print("loading incremental shader")
			shader_mat = load("res://shaders/pov_incremental.tres")
		SHADER_TYPE.FADE:
			print("loading fade shader")
			shader_mat = load("res://shaders/pov_fade.tres")
		SHADER_TYPE.FADE_FULL_COLOR:
			print("loading fade full color shader")
			shader_mat = load("res://materials/pov_fade_fullcolor.tres")
	match noise:
		NOISE_TYPE.BINARY:
			print("loading binary noise")
			noise_img = load("res://images/binary_noise-1152x648.png")
		NOISE_TYPE.LINEAR:
			print("loading linear noise")
			noise_img = load("res://images/linear_noise-1152x648.png")
		NOISE_TYPE.FULL_COLOR:
			print("loading full color noise")
			noise_img = load("res://images/rand_img_full-1152x648.png")
		NOISE_TYPE.PERLIN:
			print("loading perlin noise")
			noise_img = load("res://images/perlin_s21-c4-l5-a0.4.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## Initialize RNG
	randomize()
	
	## Set noise and shader
	noiseRect.texture = noise_img
	shaderRect.material = shader_mat
	
	## Apply resolution scale factor
	set_res_scale()
	## Take initial render snapshots
	get_snapshots()
	charCam.make_current()
	## Set initial object to find
	new_object()


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
	#get_tree().root.content_scale_size = Vector2i(1.0/resolution_scale, 1.0/resolution_scale)
	
	renderView.size.x = init_width / resolution_scale
	renderView.size.y = init_height / resolution_scale
	charView.size.x = init_width / resolution_scale
	charView.size.y = init_height / resolution_scale
	$Character.res_scale = resolution_scale
	$Character/UserInterface/RenderVPContainer/RenderViewport/OverlayVignette.size = charView.size
	
	$Character/UserInterface/Overlay.pivot_offset.x = renderView.size.x / 2.0
	$Character/UserInterface/Overlay.pivot_offset.y = renderView.size.y / 2.0
	$Character/UserInterface/Overlay.scale = Vector2(1.0 / resolution_scale, 1.0 / resolution_scale)
	#$Character/UserInterface/Overlay.position.x = (init_width / resolution_scale) - (renderView.size.x / 2)
	#$Character/UserInterface/Overlay.position.y = (init_height / resolution_scale) - (renderView.size.y / 2)


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


func new_object():
	var r = randi() % len(objects)
	while objects[r] == to_find:
		r = randi() % len(objects)
	
	to_find = objects[r]
	print('setting to_find: ' + to_find)
	update_label()


func update_label():
	$Character/UserInterface/Overlay/TextBG/Label.text = to_find + "\n" + last_click


func object_click(id):
	print(id + ' clicked')
	last_click = id
	if id == to_find:
		$Character/UserInterface/Overlay/Match.display()
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
