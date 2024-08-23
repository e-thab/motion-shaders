shader_type canvas_item;

global uniform sampler2D last_frame;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
	vec3 c = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	if (c.r > 0.0) {
		COLOR = vec4(255.0, 0.0, 0.0, 1.0);
	}
}
