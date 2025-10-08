shader_type canvas_item;

uniform float noise_speed : hint_range(0.1, 10.0) = 5.0;

// Simple noise function
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    uv.y += TIME * noise_speed * 0.1;
    
    float noise = random(uv * 100.0 + TIME);
    
    // Create static pattern
    vec3 static_color = vec3(noise);
    
    COLOR = vec4(static_color, noise * 0.6);
}
