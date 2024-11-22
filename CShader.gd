extends Node
class_name CShader
## Class to define properties for custom shaders specific to this project

enum SHADER_TYPE {
	INVERT, BINARY, INCREMENTAL,
	FADE, FADE_FULL_COLOR, OPTIC_FLOW,
	OPTIC_FLOW_ALL, TEST, NONE
}
#enum NOISE_TYPE {
	#BINARY, LINEAR, FULL_COLOR,
	#PERLIN, FILL_BLACK, FILL_WHITE
#}

## Dropdown index
var index = [
	SHADER_TYPE.INVERT,
	SHADER_TYPE.BINARY,
	SHADER_TYPE.INCREMENTAL,
	SHADER_TYPE.FADE,
	SHADER_TYPE.FADE_FULL_COLOR,
	SHADER_TYPE.OPTIC_FLOW,
	SHADER_TYPE.OPTIC_FLOW_ALL
]

## Shader parameters
const COLOR_1 = "color_1"
const COLOR_2 = "color_2"
const FADE_COLOR = "fade_color"
const FADE_SPEED = "fade_speed"
const DIFF_THRESH = "diff_threshold"
const INCREMENT = "inc"
const RES_SCALE = "res_scale"
const WIN_SIZE = "win_size"

## Instance properties
var type : SHADER_TYPE
var title : String
var description : String
var uses_noise : bool
var material : ShaderMaterial
var params : Array


func _init(shader_type : SHADER_TYPE):
	set_shader(shader_type)

func set_shader(shader_type : SHADER_TYPE):
	type = shader_type
	match shader_type:
		SHADER_TYPE.INVERT:
			title = "Invert"
			description = "Compares each stage pixel with the stage pixel from the previous frame at the same location. If the difference is higher than the Diff Threshold parameter, invert the color of the render pixel from the previous render frame."
			uses_noise = true
			material = preload("res://materials/pov.tres")
			params = []
		SHADER_TYPE.BINARY:
			title = "Binary"
			description = "{Description}"
			uses_noise = false
			material = preload("res://materials/pov_binary.tres")
			params = [COLOR_1, COLOR_2]
		SHADER_TYPE.INCREMENTAL:
			title = "Incremental"
			description = "{Description}"
			uses_noise = true
			material = preload("res://materials/pov_incremental.tres")
			params = [INCREMENT]
		SHADER_TYPE.FADE:
			title = "Fade"
			description = "{Description}"
			uses_noise = false
			material = preload("res://materials/pov_fade.tres")
			params = [FADE_COLOR, FADE_SPEED, DIFF_THRESH]
		SHADER_TYPE.FADE_FULL_COLOR:
			title = "Fade (full color)"
			description = "{Description}"
			uses_noise = false
			material = preload("res://materials/pov_fade_fullcolor.tres")
			params = [FADE_SPEED, DIFF_THRESH]
		SHADER_TYPE.OPTIC_FLOW:
			title = "Optic flow (constrained)"
			description = "{Description}"
			uses_noise = false
			material = preload("res://materials/optic_flow.tres")
			params = [RES_SCALE, WIN_SIZE, DIFF_THRESH]
		SHADER_TYPE.OPTIC_FLOW_ALL:
			title = "Optic flow (every pixel)"
			description = "{Description}"
			uses_noise = false
			material = preload("res://materials/optic_flow_all.tres")
			#menu = preload("res://scenes/menu_optic_flow_all.tscn")
			params = [RES_SCALE, WIN_SIZE]
		SHADER_TYPE.TEST:
			var testMaterial:ShaderMaterial = preload("res://materials/test.tres")
			title = testMaterial.shader.resource_path
			description = "Test shader"
			uses_noise = true
			material = testMaterial
			params = []
		SHADER_TYPE.NONE:
			title = "None"
			description = "No shader in use"
			uses_noise = false
			material = null
			params = []
