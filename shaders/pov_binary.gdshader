shader_type canvas_item;

global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 color_1: source_color;// = vec4(0.0, 1.0, 0.5, 1.0);
uniform vec4 color_2: source_color;// = vec4(0.0, 0.5, 1.0, 1.0);
uniform float diff_threshold = 0.25;

//const vec4 WHITE = vec4(1.0, 1.0, 1.0, 1.0);
const vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);

//float g(sampler2D tex, float x, float y) {
	//// Return grayscale intensity value of texture at pixel (x,y)
	//vec4 col = textureLod(tex, vec2(x, y), 0.0);
	//return col.r * 0.3 + col.g * 0.59 + col.b * 0.11;
//}

void fragment() {
	vec4 stage_color = textureLod(current_frame, SCREEN_UV, 0.0);
	vec4 last_stage_color = textureLod(last_frame, SCREEN_UV, 0.0);
	vec4 render_color = textureLod(screen_texture, SCREEN_UV, 0.0);
	//float v = textureLod(screen_texture, SCREEN_UV, 0.0).a;
	
	//float current_g = g(current_frame, SCREEN_UV.x, SCREEN_UV.y);
	//float last_g = g(last_frame, SCREEN_UV.x, SCREEN_UV.y);
	//&& abs(current_g - last_g) >= diff_threshold) {
	
	if (stage_color != BLACK && last_stage_color == BLACK) { 
		if (render_color == color_1) {
			COLOR = color_2;
			//COLOR = vec4(COLOR_2.r, COLOR_2.g, COLOR_2.b, screen_color.a);
			//COLOR.r = stage_color.r + (render_color.r - stage_color.r) * v;
			//COLOR.g = stage_color.g + (render_color.g - stage_color.g) * v;
			//COLOR.b = stage_color.b + (render_color.b - stage_color.b) * v;
		} else if (render_color == color_2) {
			COLOR = color_1;
			//COLOR = vec4(COLOR_1.r, COLOR_1.g, COLOR_1.b, screen_color.a);
		}
	} else {
		COLOR = render_color;
		//COLOR = vec4(render_color.r, render_color.g, render_color.b, screen_color.a);
	}
}