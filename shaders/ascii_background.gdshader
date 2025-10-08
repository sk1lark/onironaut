shader_type canvas_item;

// textured background like the lesser evil
uniform float time_scale : hint_range(0.0, 2.0) = 0.08;
uniform float texture_scale : hint_range(1.0, 50.0) = 20.0;
uniform float depth : hint_range(0.0, 1.0) = 0.25;

float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float noise(vec2 st) {
	vec2 i = floor(st);
	vec2 f = fract(st);
	
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	
	vec2 u = f * f * (3.0 - 2.0 * f);
	
	return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// multi-octave noise for texture
float fbm(vec2 st, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	
	for(int i = 0; i < octaves; i++) {
		value += amplitude * noise(st * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	
	return value;
}

void fragment() {
	vec2 uv = UV * texture_scale;
	
	// slow drift for atmosphere
	uv.y += TIME * time_scale * 0.1;
	uv.x += sin(TIME * time_scale * 0.15) * 0.3;
	
	// layered noise for depth
	float n1 = fbm(uv, 4);
	float n2 = fbm(uv * 1.5 + 10.0, 3);
	float n3 = fbm(uv * 0.5 + 20.0, 2);
	
	// combine layers
	float pattern = n1 * 0.5 + n2 * 0.3 + n3 * 0.2;
	
	// add some graininess
	float grain = random(uv + TIME * 0.01) * 0.1;
	pattern += grain;
	
	// darker overall like the lesser evil
	pattern = pattern * depth;
	
	COLOR = vec4(vec3(pattern), 1.0);
}
