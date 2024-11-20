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

var type : SHADER_TYPE
var title : String
var uses_noise : bool
var material : ShaderMaterial
var menu : Resource

func _init(shader_type : SHADER_TYPE):
	set_shader(shader_type)

func set_shader(shader_type : SHADER_TYPE):
	type = shader_type
	match shader_type:
		SHADER_TYPE.INVERT:
			title = "Invert"
			uses_noise = true
			material = preload("res://materials/pov.tres")
			menu = null
		SHADER_TYPE.BINARY:
			title = "Binary"
			uses_noise = false
			material = preload("res://materials/pov_binary.tres")
			menu = null
		SHADER_TYPE.INCREMENTAL:
			title = "Incremental"
			uses_noise = true
			material = preload("res://materials/pov_incremental.tres")
			menu = null
		SHADER_TYPE.FADE:
			title = "Fade"
			uses_noise = false
			material = preload("res://materials/pov_fade.tres")
			menu = null
		SHADER_TYPE.FADE_FULL_COLOR:
			title = "Fade (full color)"
			uses_noise = false
			material = preload("res://materials/pov_fade_fullcolor.tres")
			menu = null
		SHADER_TYPE.OPTIC_FLOW:
			title = "Optic flow (constrained)"
			uses_noise = false
			material = preload("res://materials/optic_flow.tres")
			menu = null
		SHADER_TYPE.OPTIC_FLOW_ALL:
			title = "Optic flow (every pixel)"
			uses_noise = false
			material = preload("res://materials/optic_flow_all.tres")
			#menu = preload("res://scenes/menu_optic_flow_all.tscn")
			menu = null
		SHADER_TYPE.TEST:
			var testMaterial:ShaderMaterial = preload("res://materials/test.tres")
			title = testMaterial.shader.resource_path
			uses_noise = true
			material = testMaterial
			menu = null
		SHADER_TYPE.NONE:
			title = "None"
			uses_noise = false
			material = null
			menu = null
