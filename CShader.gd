extends Node
class_name CShader
## Class to define properties for custom shaders specific to this project

enum SHADER_TYPE {
	INVERT, BINARY, INCREMENTAL,
	FADE, FADE_FULL_COLOR, OPTIC_FLOW,
	OPTIC_FLOW_ALL, TEST, NONE
}

## Shader parameters
const COLOR_1 = "color_1"
const COLOR_2 = "color_2"
const FADE_COLOR = "fade_color"
const FADE_SPEED = "fade_speed"
const DIFF_THRESH = "diff_threshold"
const INCREMENT = "inc"
const RES_SCALE = "res_scale"
const WIN_SIZE = "win_size"

## Default param values
const default = {
	COLOR_1: Color(0.0, 1.0, 0.5, 1.0),
	COLOR_2: Color(0.0, 0.5, 1.0, 1.0),
	FADE_COLOR: Color(0.0, 1.0, 0.5, 1.0),
	FADE_SPEED: 0.06,
	DIFF_THRESH: 0.25,
	INCREMENT: 0.15,
	RES_SCALE: 1.0,
	WIN_SIZE: 5.0
}

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
			description = "Compares each stage pixel with the stage pixel from the previous frame at the same location. If the difference is higher than the diff Threshold parameter, invert the color of the render pixel from the previous render frame."
			uses_noise = true
			material = preload("res://materials/pov.tres")
			params = [DIFF_THRESH]
		SHADER_TYPE.BINARY:
			title = "Binary"
			description = "Compares each stage pixel with the stage pixel from the previous frame at the same location. If the difference is higher than the diff Threshold parameter, swap render color between Color 1 and Color 2 parameters."
			uses_noise = false
			material = preload("res://materials/pov_binary.tres")
			params = [COLOR_1, COLOR_2, DIFF_THRESH]
		SHADER_TYPE.INCREMENTAL:
			title = "Incremental"
			description = "If the difference between current and last stage pixel is greater than the diff threshold param, nudge render pixel color a small amount toward black or white. The direction they're nudged flips whenever they reach pure black or white."
			uses_noise = true
			material = preload("res://materials/pov_increment.tres")
			params = [INCREMENT, DIFF_THRESH]
		SHADER_TYPE.FADE:
			title = "Fade"
			description = "If the difference between current and last stage pixel is greater than the diff threshold param, set render pixel color to the fade color param. If nothing changes, nudge pixels toward black according to the fade speed param."
			uses_noise = false
			material = preload("res://materials/pov_fade.tres")
			params = [FADE_COLOR, FADE_SPEED, DIFF_THRESH]
		SHADER_TYPE.FADE_FULL_COLOR:
			title = "Fade (full color)"
			description = "If the difference between current and last stage pixel is greater than the diff threshold param, set render pixel color to the stage pixel color. If nothing changes, nudge pixels toward black according to the fade speed param."
			uses_noise = false
			material = preload("res://materials/pov_fade_fullcolor.tres")
			params = [FADE_SPEED, DIFF_THRESH]
		SHADER_TYPE.OPTIC_FLOW:
			title = "Optic flow (constrained)"
			description = "If the difference between current and last stage pixel is greater than the diff threshold param, iterate over pixels in a small neighborhood (Win Size) of pixels around current. Set render color to indicate the direction the pixel is most likely moving in."
			uses_noise = false
			material = preload("res://materials/optic_flow.tres")
			params = [RES_SCALE, WIN_SIZE, DIFF_THRESH]
		SHADER_TYPE.OPTIC_FLOW_ALL:
			title = "Optic flow (every pixel)"
			description = "Iterate over pixels in a small neighborhood (Win Size) of pixels around current. Set render color to indicate the direction the pixel is most likely moving in. Applied to every pixel rather than according to diff threshold."
			uses_noise = false
			material = preload("res://materials/optic_flow_all.tres")
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
