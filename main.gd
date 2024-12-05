extends Node3D

@export var resolution_scale : int = 2
@export var shader_type : CShader.SHADER_TYPE = CShader.SHADER_TYPE.INVERT
@export var noise_type : NOISE_TYPE = NOISE_TYPE.BINARY

@onready var rod : MeshInstance3D = $Rod
@onready var cube : Node3D = $Cube
@onready var flow_sprite = $UserInterface/HeadcamVPContainer/HeadcamViewport/Camera/FlowTestSprite

@onready var character : CharacterBody3D = $Character
@onready var debugPanel : PanelContainer = $UserInterface/Overlay/DebugPanel
@onready var charView : SubViewport = $UserInterface/HeadcamVPContainer/HeadcamViewport
@onready var charCam : Camera3D = $Character.CAMERA
@onready var renderViewContainer : SubViewportContainer = $UserInterface/RenderVPContainer
@onready var renderView : SubViewport = $UserInterface/RenderVPContainer/RenderViewport
@onready var spawnPos : Vector3 = $Character.position

## Menu nodes
@onready var shaderMenu : BoxContainer = $UserInterface/Overlay/ShaderMenu
#@onready var shaderTitle : Label = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/ShaderHBoxContainer/TitleLabel
@onready var shaderDescContainer : PanelContainer = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/ShaderDescriptionContainer
@onready var shaderDesc : Label = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/ShaderDescriptionContainer/MarginContainer/DescriptionLabel
@onready var shaderDescBtn : Button = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/ShaderHBoxContainer/ShaderDescriptionButton
@onready var noiseDescContainer : PanelContainer = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/NoiseDescriptionContainer
@onready var noiseDesc : Label = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/NoiseDescriptionContainer/MarginContainer/DescriptionLabel
@onready var noiseDescBtn : Button = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/NoiseHBoxContainer/NoiseDescriptionButton
## Param submenu nodes
@onready var paramColor1 : HBoxContainer = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/Color1
@onready var paramColor1Input : ColorPickerButton = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/Color1/Color1Picker
@onready var paramColor2 : HBoxContainer = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/Color2
@onready var paramColor2Input : ColorPickerButton = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/Color2/Color2Picker
@onready var paramFadeColor : HBoxContainer = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/FadeColor
@onready var paramFadeColorInput : ColorPickerButton = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/FadeColor/FadeColorPicker
@onready var paramFadeSpeed : HBoxContainer = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/FadeSpeed
@onready var paramFadeSpeedInput : SpinBox = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/FadeSpeed/FadeSpeedSpinBox
@onready var paramDiffThresh : HBoxContainer = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/DiffThreshold
@onready var paramDiffThreshInput : SpinBox = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/DiffThreshold/DiffThreshSpinBox
@onready var paramWinSize : HBoxContainer = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/WinSize
@onready var paramWinSizeInput : SpinBox = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/WinSize/WinSizeSpinBox
@onready var paramResScale : HBoxContainer = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/ResScale
@onready var paramResScaleInput : SpinBox = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/ResScale/ResScaleSpinBox
@onready var paramInc : HBoxContainer = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/Increment
@onready var paramIncInput : SpinBox = $UserInterface/Overlay/ShaderMenu/PanelContainer/MarginContainer/VBoxContainer/Increment/IncSpinBox

@onready var noiseRect : Sprite2D = $UserInterface/RenderVPContainer/RenderViewport/BG
@onready var shaderRect : Sprite2D = $UserInterface/RenderVPContainer/RenderViewport/OverlayFull

@onready var shader : CShader = CShader.new(shader_type)

## Strings to use for collapse/expand description button
const SHOW_DESC = " ▼ "
const HIDE_DESC = " ▲ "

## Initial screen resolution
const init_width = 1152
const init_height = 648

## Misc variables
var time_elapsed = 0.0
var paused = false
var capturing_mouse = true
var showing_shader_desc = true
var showing_noise_desc = true
var noise_name
#var occluding = true -- no longer used

## Objects to find
var objects = ["fish", "lily pad", "flower", "cat tails", "cube", "sphere", "foliage"]
var to_find = ""
var last_click = "none"

enum NOISE_TYPE {
	BINARY, LINEAR, FULL_COLOR,
	PERLIN, FILL_BLACK, FILL_WHITE
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Apply resolution scale factor
	set_res_scale()
	# Set shader and noise from export vars
	set_shader()
	set_noise()
	#if not shader.uses_noise:
		#noiseRect.hide()
	
	# Set the current_frame shader param to the texture of the viewport assigned
	# to the character camera
	RenderingServer.global_shader_parameter_set("current_frame", charView.get_texture())
	# Connect the frame_post_draw signal to call post_draw() after each frame is drawn
	RenderingServer.connect("frame_post_draw", post_draw)
	
	# Initialize RNG
	randomize()
	# Set initial object to find
	new_object()
	
	
	# Hide shader/noise descriptions
	_on_shader_description_button_pressed()
	_on_noise_description_button_pressed()


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
	#if Input.is_action_just_pressed("pause"):
		#paused = !paused
	
	#if Input.is_action_just_pressed("shader_toggle"):
		#capturing_mouse = !capturing_mouse
		#match Input.mouse_mode:
			#Input.MOUSE_MODE_CAPTURED:
				#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			#Input.MOUSE_MODE_VISIBLE:
				#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	## Toggle capture input state (only raycast while true)
	if Input.is_action_just_pressed("ui_cancel"):
		capturing_mouse = !capturing_mouse
	
	## Show/hide shader overlay
	if Input.is_action_just_pressed("shader_toggle"):
		if renderViewContainer.visible:
			renderViewContainer.hide()
		else:
			renderViewContainer.show()
			if shader.uses_noise:
				noiseRect.show()
		$Pond/Water.visible = !renderViewContainer.visible
	
	## Show/hide shader menu
	if Input.is_action_just_pressed("toggle_menu"):
		shaderMenu.visible = !shaderMenu.visible
		if shaderMenu.visible:
			$UserInterface/Overlay/MenuHintPanel.hide()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			capturing_mouse = false
		else:
			$UserInterface/Overlay/MenuHintPanel.show()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			capturing_mouse = true
	
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
	#if Input.is_action_just_pressed("toggle_occlusion"):
		#if occluding:
			#occluding = false
			#get_tree().call_group("fill", "hide")
			#print("occlusion off")
		#else:
			#occluding = true
			#get_tree().call_group("fill", "show")
			#print("occlusion on")
	
	## Register object click
	if Input.is_action_just_pressed("click") and capturing_mouse:
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
	
	## Respawn if char has fallen some distance... just in case
	if character.position.y < -50.0:
		character.position = spawnPos


func post_draw():
	## After frame draw: get a snapshot of the current stage view and apply the
	## shader parameter so shaders can read from the previous frame
	var snap = charView.get_texture().get_image()
	RenderingServer.global_shader_parameter_set("last_frame", ImageTexture.create_from_image(snap))
	
	# Noise rect only needs to be visible for one frame when set.
	if noiseRect.visible:
		noiseRect.hide()


func set_shader():
	## Create/set shader to a CShader instance based on current shader_type
	shader.set_shader(shader_type)
	print("using shader: ", shader.title)
	debugPanel.add_property("Shader", shader.title, Debug.SHADER)
	shaderDesc.text = shader.description
	
	# 
	if shader_type == CShader.SHADER_TYPE.NONE:
		renderViewContainer.hide()
		return
	shaderRect.material = shader.material
	noiseRect.visible = shader.uses_noise
	
	var params = shader.params
	print("params: ", params)
	# Populate menu item values with current shader vals
	for p_type in params:
		var p_val = shader.material.get_shader_parameter(p_type)
		# Convert to color value for color-based params
		if p_type in [CShader.COLOR_1, CShader.COLOR_2, CShader.FADE_COLOR]:
			p_val = Color(p_val[0], p_val[1], p_val[2])
		set_shader_param(p_type, p_val, true)
	
	# Display param menu options according to actual shader params
	paramColor1.visible = CShader.COLOR_1 in params
	paramColor2.visible = CShader.COLOR_2 in params
	paramDiffThresh.visible = CShader.DIFF_THRESH in params
	paramFadeColor.visible = CShader.FADE_COLOR in params
	paramFadeSpeed.visible = CShader.FADE_SPEED in params
	paramResScale.visible = CShader.RES_SCALE in params
	paramInc.visible = CShader.INCREMENT in params
	paramWinSize.visible = CShader.WIN_SIZE in params


func set_shader_param(p_type, p_val, menu_only=false):
	## Set given shader parameter p_type to value p_val
	if !menu_only:
		shader.material.set_shader_parameter(p_type, p_val)
	
	# Set param menu button
	match p_type:
		CShader.COLOR_1:
			print(p_val)
			paramColor1Input.color = p_val
		CShader.COLOR_2:
			paramColor2Input.color = p_val
		CShader.DIFF_THRESH:
			paramDiffThreshInput.value = p_val
		CShader.FADE_COLOR:
			paramFadeColorInput.color = p_val
		CShader.FADE_SPEED:
			paramFadeSpeedInput.value = p_val
		CShader.RES_SCALE:
			paramResScaleInput.value = p_val
		CShader.INCREMENT:
			paramIncInput.value = p_val
		CShader.WIN_SIZE:
			paramWinSizeInput.value = p_val


func set_shader_param_default(p_type):
	## Set given shader parameter p_type to its default value
	set_shader_param(p_type, CShader.default[p_type])


func set_noise():
	## Set noise from export var
	noiseRect.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	match noise_type:
		NOISE_TYPE.BINARY:
			noise_name = "Black or white"
			noiseRect.texture = load("res://images/binary_noise-1152x648.png")
			noiseDesc.text = "Each pixel is randomly assigned color values of either black or white."
		NOISE_TYPE.LINEAR:
			noise_name = "Grayscale"
			noiseRect.texture = load("res://images/linear_noise-1152x648.png")
			noiseDesc.text = "Each pixel is randomly assigned a value in the range from black to white."
		NOISE_TYPE.FULL_COLOR:
			noise_name = "Full spectrum"
			noiseRect.texture = load("res://images/rand_img_full-1152x648.png")
			noiseDesc.text = "Each pixel is randomly assigned any possible color value."
		NOISE_TYPE.PERLIN:
			noise_name = "Perlin"
			noiseRect.texture = load("res://images/perlin_s21-c4-l5-a0.4.png")
			noiseDesc.text = "Gray scale gradient noise that appears smoother and more natural."
		NOISE_TYPE.FILL_BLACK:
			noise_name = "Fill (black)"
			noiseRect.texture = load("res://images/white-1152x648.png")
			noiseRect.self_modulate = Color(0.0, 0.0, 0.0)
			noiseDesc.text = "Solid black fill"
		NOISE_TYPE.FILL_WHITE:
			noise_name = "Fill (white)"
			noiseRect.texture = load("res://images/white-1152x648.png")
			noiseDesc.text = "Solid white fill"
	print("using noise: ", noise_name)
	debugPanel.add_property("Noise", noise_name, Debug.NOISE)
	
	# Refresh noise texture
	if shader.uses_noise:
		noiseRect.hide()
		noiseRect.show()


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
	
	# Set render viewport to 'once' clear mode so that it clears next frame, but
	# not again until manually set. Effectively refreshes viewport
	renderView.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	
	# Show noise rect to refresh
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
	# Top left -> Top right
	if x < rightX and y == topY:
		flow_sprite.position.x = clamp(x + delta*speed, leftX, rightX)
	# Top right -> Bottom right
	elif x == rightX and y < botY:
		flow_sprite.position.y = clamp(y + delta*speed, topY, botY)
	# Bottom right -> Top left (diagonal)
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
	if to_find in ["flower", "lily pad"]:
		$UserInterface/Overlay/ObjectivePanel/MarginContainer/Label.text = "Click on a " + to_find
	else:
		$UserInterface/Overlay/ObjectivePanel/MarginContainer/Label.text = "Click on the " + to_find


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

func _on_noise_option_button_item_selected(index: int) -> void:
	var last_noise = noise_type
	match index:
		0: noise_type = NOISE_TYPE.BINARY
		1: noise_type = NOISE_TYPE.LINEAR
		2: noise_type = NOISE_TYPE.FULL_COLOR
		3: noise_type = NOISE_TYPE.PERLIN
		4: noise_type = NOISE_TYPE.FILL_BLACK
		5: noise_type = NOISE_TYPE.FILL_WHITE
	if noise_type != last_noise:
		set_noise()

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

func _on_inc_spin_box_value_changed(value: float) -> void:
	shader.material.set_shader_parameter(CShader.INCREMENT, value)

## Shader param reset buttons
func _on_color_1_reset_button_pressed() -> void:
	set_shader_param_default(CShader.COLOR_1)

func _on_color_2_reset_button_pressed() -> void:
	set_shader_param_default(CShader.COLOR_2)

func _on_fade_color_reset_button_pressed() -> void:
	set_shader_param_default(CShader.FADE_COLOR)

func _on_fade_speed_reset_button_pressed() -> void:
	set_shader_param_default(CShader.FADE_SPEED)

func _on_diff_thresh_reset_button_pressed() -> void:
	set_shader_param_default(CShader.DIFF_THRESH)

func _on_win_size_reset_button_pressed() -> void:
	set_shader_param_default(CShader.WIN_SIZE)

func _on_res_scale_reset_button_pressed() -> void:
	set_shader_param_default(CShader.RES_SCALE)

func _on_inc_reset_button_pressed() -> void:
	set_shader_param_default(CShader.INCREMENT)
