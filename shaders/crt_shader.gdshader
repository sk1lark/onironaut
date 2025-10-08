shader_type canvas_item;

// CRT Monitor simulation parameters
uniform float screen_curve : hint_range(0.0, 10.0) = 3.0;
uniform float wobble_intensity : hint_range(0.0, 0.01) = 0.004;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.6;
uniform float scanline_count : hint_range(100.0, 800.0) = 270.0;
uniform float brightness : hint_range(0.0, 2.0) = 1.1;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.5;
uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.002;
uniform float pixel_distortion : hint_range(0.0, 1.0) = 0.3;

// Get screen texture
uniform sampler2D screen_texture : hint_screen_texture;

vec2 curve_screen(vec2 uv) {
    uv = uv * 2.0 - 1.0;  // Transform to -1 to 1 range
    vec2 offset = abs(uv.yx) / vec2(screen_curve, screen_curve);
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;  // Transform back to 0 to 1 range
    return uv;
}

void fragment() {
    vec2 screen_uv = curve_screen(SCREEN_UV);

    // Add wobble effect
    screen_uv.x += sin(TIME * 3.0 + screen_uv.y * 50.0) * wobble_intensity;
    screen_uv.y += cos(TIME * 2.0 + screen_uv.x * 30.0) * wobble_intensity * 0.5;

    // Sample the screen texture
    vec3 color = texture(screen_texture, screen_uv).rgb;

    // Apply chromatic aberration (always on for 1-bit CRT feel)
    vec2 chroma_offset = vec2(chromatic_aberration, 0.0);
    color.r = texture(screen_texture, screen_uv + chroma_offset).r;
    color.g = texture(screen_texture, screen_uv).g;
    color.b = texture(screen_texture, screen_uv - chroma_offset).b;
    
    // Apply glitch effect (enhanced chromatic aberration)
    if (glitch_intensity > 0.0) {
        float glitch = glitch_intensity;
        vec2 offset = vec2(0.005 * glitch, 0.0);
        color.r = texture(screen_texture, screen_uv + offset).r;
        color.b = texture(screen_texture, screen_uv - offset).b;
    }
    
    // Pixel distortion (grid effect)
    if (pixel_distortion > 0.0) {
        vec2 pixel_uv = floor(screen_uv * 200.0) / 200.0;
        float pixel_noise = fract(sin(dot(pixel_uv, vec2(12.9898, 78.233))) * 43758.5453);
        color *= 1.0 - (pixel_noise * pixel_distortion * 0.1);
    }

    // Add scanlines (enhanced)
    float scanlines = sin(screen_uv.y * scanline_count * PI) * scanline_intensity;
    scanlines = (scanlines * 0.06) + 0.94;
    color *= scanlines;
    
    // Add horizontal scanline roll
    float roll = sin(TIME * 0.5 + screen_uv.y * 2.0) * 0.02;
    color *= 1.0 + roll;

    // Apply vignette
    vec2 vignetteUV = SCREEN_UV;
    vignetteUV *= 1.0 - vignetteUV.yx;
    float vignette = vignetteUV.x * vignetteUV.y * 15.0;
    vignette = pow(vignette, vignette_strength);

    // Apply brightness and vignette
    color *= brightness * vignette;

    // Ensure we're in bounds
    if (screen_uv.x < 0.0 || screen_uv.x > 1.0 || screen_uv.y < 0.0 || screen_uv.y > 1.0) {
        color = vec3(0.0);
    }

    COLOR = vec4(color, 1.0);
}