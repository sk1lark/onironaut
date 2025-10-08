shader_type canvas_item;

// vignette for atmospheric depth
uniform float intensity : hint_range(0.0, 1.0) = 0.6;
uniform float falloff : hint_range(0.1, 2.0) = 0.8;

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv);
	
	// smooth vignette
	float vignette = smoothstep(falloff, 0.0, dist);
	vignette = 1.0 - vignette;
	vignette = pow(vignette, 2.0);
	
	// apply intensity
	vignette *= intensity;
	
	COLOR = vec4(0.0, 0.0, 0.0, vignette);
}
