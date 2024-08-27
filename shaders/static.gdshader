shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float frequency = 600;
uniform float depth = 0.07;

float random( vec2 p ) {
	// e^pi (Gelfond's constant)
	// 2^sqrt(2) (Gelfond–Schneider constant)
	vec2 K1 = vec2( 23.14069263277926, 2.665144142690225 );
	
	//return fract( cos( mod( 12345678., 256. * dot(p,K1) ) ) ); // ver1
	//return fract(cos(dot(p,K1)) * 123456.); // ver2
	return fract(cos(dot(p,K1)) * 12345.6789); // ver3
}

void fragment() {
	// Random static:
	//COLOR = vec4(
		//random(vec2(UV.x*TIME, UV.y*TIME)),
		//random(vec2(UV.x*TIME, UV.y*TIME)),
		//random(vec2(UV.x*TIME, UV.y*TIME)),
		//1.0
	//);
	
	vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);
	vec4 WHITE = vec4(255.0, 255.0, 255.0, 1.0);
	
	float r = random(vec2(UV.x, UV.y));
	
	// Maybe try adding another viewport/shader layer that 'keeps track' of switched pixels by copying
	// previous frame pixels from BackBufferCopy?
	
	//vec4 r = vec4(
		//random(vec2(UV.x, UV.y)),
		//random(vec2(UV.x, UV.y)),
		//random(vec2(UV.x, UV.y)),
		//1.0
	//);
	
	bool white = true;
	if (r > 0.5) {
		white = true;
		COLOR = WHITE;
	} else{
		white = false;
		COLOR = BLACK;
	}
	
	vec3 c = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	
	if (c.r > 0.0) {
		//if (int(TIME * 1000.0) % 2 == 0) {
			//if (white) {
				//COLOR = BLACK;
			//} else {
				//COLOR = WHITE;
			//}
		//}
		COLOR = vec4(
			random(vec2(UV.x*TIME, UV.y*TIME)),
			random(vec2(UV.x*TIME, UV.y*TIME)),
			random(vec2(UV.x*TIME, UV.y*TIME)),
			1.0
		);
	} else {
		//COLOR = BLACK;
	}
}

//void fragment() {
	//vec2 uv = SCREEN_UV;
	//uv.x += sin(uv.y * frequency + TIME) * depth;
	//uv.x = clamp(uv.x, 0.0, 1.0);
	//vec3 c = textureLod(screen_texture, uv, 0.0).rgb;
//
	//COLOR.rgb = c;
//}
