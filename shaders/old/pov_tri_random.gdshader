shader_type canvas_item;

global uniform sampler2D last_stage;
global uniform sampler2D second_last_stage;
global uniform sampler2D last_render;
//uniform sampler2D screen_texture: hint_screen_texture, filter_nearest;

uniform vec4 WHITE = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);

uniform vec4 RED = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 GREEN = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 BLUE = vec4(0.0, 0.0, 1.0, 1.0);

highp float rand(vec2 co) {
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt= dot(co.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

void fragment() {
	vec4 stage_color = textureLod(last_stage, SCREEN_UV, 0.0).rgba;
	vec4 last_stage_color = textureLod(second_last_stage, SCREEN_UV, 0.0).rgba;
	vec4 render_color = textureLod(last_render, SCREEN_UV, 0.0).rgba;
	float r = rand(vec2(SCREEN_UV.x * TIME, SCREEN_UV.y * TIME));

	//float co = 1.0 - max3(r, g, b);
	//vec4 rand_color = vec4(
		//r + co,
		//g + co,
		//b + co,
		//1.0
	//);

	if (stage_color == WHITE && last_stage_color == BLACK) {
		if (r <= (1.0/3.0)) {
			COLOR = RED;
		} else if (r <= (2.0/3.0)) {
			COLOR = GREEN;
		} else {
			COLOR = BLUE;
		}
		//if (render_color == WHITE) {
			//COLOR = BLACK;
		//} else {
			//COLOR = WHITE;
		//}
	} else {
		COLOR = render_color;
	}
}