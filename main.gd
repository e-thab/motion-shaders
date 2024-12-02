extends Node3D

@export var resolution_scale : int = 2
@export var shader_type : CShader.SHADER_TYPE = CShader.SHADER_TYPE.INVERT
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

## Menu nodes
@onready var shaderMenu : PanelContainer = $UserInterface/Overlay/ShaderMenu
#@onready var shaderTitle : Label = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/ShaderHBoxContainer/TitleLabel
@onready var shaderDescContainer : PanelContainer = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/ShaderDescriptionContainer
@onready var shaderDesc : Label = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/ShaderDescriptionContainer/MarginContainer/DescriptionLabel
@onready var shaderDescBtn : Button = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/ShaderHBoxContainer/ShaderDescriptionButton
@onready var noiseDescContainer : PanelContainer = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/NoiseDescriptionContainer
@onready var noiseDesc : Label = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/NoiseDescriptionContainer/MarginContainer/DescriptionLabel
@onready var noiseDescBtn : Button = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/NoiseHBoxContainer/NoiseDescriptionButton
## Param submenu nodes
@onready var paramColor1 : HBoxContainer = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/Color1
@onready var paramColor2 : HBoxContainer = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/Color2
@onready var paramFadeColor : HBoxContainer = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/FadeColor
@onready var paramFadeSpeed : HBoxContainer = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/FadeSpeed
@onready var paramDiffThresh : HBoxContainer = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/DiffThreshold
@onready var paramWinSize : HBoxContainer = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/WinSize
@onready var paramResScale : HBoxContainer = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/ResScale
@onready var paramInc : HBoxContainer = $UserInterface/Overlay/ShaderMenu/MarginContainer/VBoxContainer/Increment

@onready var noiseRect : Sprite2D = $UserInterface/RenderVPContainer/RenderViewport/BG
@onready var shaderRect : Sprite2D = $UserInterface/RenderVPContainer/RenderViewport/OverlayFull

@onready var shader : CShader = CShader.new(shader_type)

## Strings to use for collapse/expand description button
const SHOW_DESC = " ▼ "
const HIDE_DESC = " ▲ "

var time_elapsed = 0.0
var frame_time = 2.0
var snap = 0
var paused = false
var capturing = true
var occluding = true
#var using_noise = true  # If the shader being used relies on the noise texture
var noise_name
var showing_shader_desc = true
var showing_noise_desc = true

var init_width = 1152
var init_height = 648

#var stage_tex
#var last_stage_tex

var objects = ["fish", "lily pad", "flower", "cat tails", "cube", "sphere"]
var to_find = ""
var last_click = "none"
@onready var flow_sprite = $UserInterface/HeadcamVPContainer/HeadcamViewport/Camera/FlowTestSprite

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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	## Add FPS to debug panel
	#debugPanel.add_property("FPS", Performance.get_monitor(Performance.TIME_FPS), 0)
	
	if Input.is_action_just_pressed("screenshot"):
		var r_img = renderView.get_texture().get_image()
		var c_img = charView.get_texture().get_image()
		var time = Time.get_datetime_string_from_system(false, true).replace(":", "-")
		r_img.save_png("res://screenshots/screen-" + time + "-" + str(time_elapsed) + "-r.png")
		c_img.save_png("res://screenshots/screen-" + time + "-" + str(time_elapsed) + "-c.png")
	
	## Toggle debug menu
	if Input.is_action_just_pressed("toggle_debug"):
		debugPanel.visible = !debugPanel.visible
	
	## Toggle pause time state
	if Input.is_action_just_pressed("pause"):
		paused = !paused
	
	## Toggle capture input state (only raycast while true)
	if Input.is_action_just_pressed("ui_cancel"):
		capturing = !capturing
	
	## Show/hide shader overlay
	if Input.is_action_just_pressed("shader_toggle"):
		if renderViewContainer.visible:
			renderViewContainer.hide()
		else:
			renderViewContainer.show()
			if shader.uses_noise:
				noiseRect.show()
	
	## Show/hide shader menu
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
	
	## Register object click
	if Input.is_action_just_pressed("click") and capturing:
		var coll = $UserInterface/HeadcamVPContainer/HeadcamViewport/Camera/RayCast3D.get_collider()
		if coll != null and coll.is_in_group("clickable"):
			for group in coll.get_groups():
				if group in objects:
					object_click(group)
					break
	
	if !paused:
		## Oscillate the rod & rotate the cube
		rod.position.x = 3 * cos(time_elapsed*PI/6)
		time_elapsed += delta
		cube.rotate(Vector3.UP, delta*PI/4)
		
		## Move the flow testing sprite
		if flow_sprite.visible:
			move_flow_sprite(delta)
	
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
	#shaderInfo.text = "Shader: " + shader.title + "\n" + shader.description
	#shaderTitle.text = "Shader: " + shader.title
	shaderDesc.text = shader.description
	
	if shader_type == CShader.SHADER_TYPE.NONE:
		renderViewContainer.hide()
		return
	
	shaderRect.material = shader.material
	#if shader.menu:
		#var menu = shader.menu.instantiate()
		#shaderMenu.add_child(menu)
	
	## Show param menu options according to shader params
	var params = shader.params
	paramColor1.visible = CShader.COLOR_1 in params
	paramColor2.visible = CShader.COLOR_2 in params
	paramDiffThresh.visible = CShader.DIFF_THRESH in params
	paramFadeColor.visible = CShader.FADE_COLOR in params
	paramFadeSpeed.visible = CShader.FADE_SPEED in params
	paramResScale.visible = CShader.RES_SCALE in params
	paramInc.visible = CShader.INCREMENT in params
	paramWinSize.visible = CShader.WIN_SIZE in params


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

func move_flow_sprite(delta):
	## Move sprite attached to camera for optic flow testing
	var speed = 250
	var leftX = 1152*(1.0/4.0)
	var rightX = 1152*(3.0/4.0)
	var topY = 648*(1.0/4.0)
	var botY = 648*(3.0/4.0)
	var x = flow_sprite.position.x
	var y = flow_sprite.position.y
	##TL -> TR
	if x < rightX and y == topY:
		flow_sprite.position.x = clamp(x + delta*speed, leftX, rightX)
	##TR -> BR
	elif x == rightX and y < botY:
		flow_sprite.position.y = clamp(y + delta*speed, topY, botY)
		#print(y, ", ", botY, ", ", delta, ", ", clamp(y + delta*speed, topY, botY))
	###BR -> BL
	#elif x > leftX and y == botY:
		#flow_sprite.position.x = clamp(flow_sprite.position.x - delta*speed, leftX, rightX)
	###BL -> TL
	#elif x == leftX and y > topY:
		#flow_sprite.position.y = clamp(flow_sprite.position.y - delta*speed, topY, botY)
	##BR -> TL (diagonal)
	else:
		flow_sprite.position.x = clamp(x - delta*speed, leftX, rightX)
		flow_sprite.position.y = clamp(y - delta*speed, topY, botY)


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


func _on_shader_description_button_pressed() -> void:
	showing_shader_desc = !showing_shader_desc
	shaderDescContainer.visible = showing_shader_desc
	if showing_shader_desc:
		shaderDescBtn.text = HIDE_DESC
	else:
		shaderDescBtn.text = SHOW_DESC

func _on_noise_description_button_pressed() -> void:
	showing_noise_desc = !showing_noise_desc
	noiseDescContainer.visible = showing_noise_desc
	if showing_noise_desc:
		noiseDescBtn.text = HIDE_DESC
	else:
		noiseDescBtn.text = SHOW_DESC

func _on_shader_option_button_item_selected(index: int) -> void:
	var last_shader = shader_type
	match index:
		0: shader_type = CShader.SHADER_TYPE.INVERT
		1: shader_type = CShader.SHADER_TYPE.BINARY
		2: shader_type = CShader.SHADER_TYPE.INCREMENTAL
		3: shader_type = CShader.SHADER_TYPE.FADE
		4: shader_type = CShader.SHADER_TYPE.FADE_FULL_COLOR
		5: shader_type = CShader.SHADER_TYPE.OPTIC_FLOW
		6: shader_type = CShader.SHADER_TYPE.OPTIC_FLOW_ALL
	if shader_type != last_shader:
		set_shader()

## Shader param signals from menu value changes
func _on_res_scale_spin_box_value_changed(value: float) -> void:
	shader.material.set_shader_parameter(CShader.RES_SCALE, value)

func _on_diff_thresh_spin_box_value_changed(value: float) -> void:
	shader.material.set_shader_parameter(CShader.DIFF_THRESH, value)

func _on_win_size_spin_box_value_changed(value: float) -> void:
	shader.material.set_shader_parameter(CShader.WIN_SIZE, value)

func _on_color_1_picker_color_changed(color: Color) -> void:
	shader.material.set_shader_parameter(CShader.COLOR_1, color)

func _on_color_2_picker_color_changed(color: Color) -> void:
	shader.material.set_shader_parameter(CShader.COLOR_2, color)

func _on_fade_color_picker_color_changed(color: Color) -> void:
	shader.material.set_shader_parameter(CShader.FADE_COLOR, color)

func _on_fade_speed_spin_box_value_changed(value: float) -> void:
	shader.material.set_shader_parameter(CShader.FADE_SPEED, value)
