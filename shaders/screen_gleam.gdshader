shader_type canvas_item;

// Screen gleam effect - simulates light reflecting off a CRT glass surface
uniform float gleam_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float gleam_size : hint_range(0.1, 2.0) = 0.8;
uniform vec2 light_position = vec2(0.3, 0.2);

void fragment() {
    vec2 uv = UV;

    // Calculate distance from light source
    float dist = distance(uv, light_position);

    // Create radial gleam gradient
    float gleam = 1.0 - smoothstep(0.0, gleam_size, dist);
    gleam = pow(gleam, 3.0) * gleam_intensity;

    // Add subtle horizontal streaks (like light hitting curved glass)
    float streak = sin(uv.y * 30.0 + uv.x * 10.0) * 0.02;
    gleam += streak * gleam_intensity * 0.3;

    // Subtle edge reflection
    vec2 edge_dist = abs(uv - 0.5) * 2.0;
    float edge = (edge_dist.x * edge_dist.y) * 0.15;

    vec3 gleam_color = vec3(1.0, 1.0, 1.0) * (gleam + edge);

    COLOR = vec4(gleam_color, gleam + edge);
}
