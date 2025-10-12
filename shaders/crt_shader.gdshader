shader_type canvas_item;

// Authentic CRT Monitor simulation parameters
// Godot 4: explicitly declare the screen texture using hint_screen_texture
// Use nearest filtering for the screen texture to preserve the sharp CRT subpixel/pixel look
// even when project default filtering is set to linear. Nearest sampling avoids unwanted
// blurring introduced by global settings (useful for pixel/CRT styles).
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest_mipmap;

uniform float screen_curve : hint_range(0.0, 10.0) = 6.0;
uniform float wobble_intensity : hint_range(0.0, 0.01) = 0.002;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.8;
// Fewer lines + larger thickness = much thicker, more pronounced scanlines by default
uniform float scanline_count : hint_range(10.0, 800.0) = 120.0;
// Controls thickness (in pixels) of the horizontal scanlines. Larger = thicker lines.
uniform float scan_thickness : hint_range(0.5, 48.0) = 10.0;
uniform float brightness : hint_range(0.0, 2.0) = 1.15;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.7;
uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.004;
uniform float phosphor_strength : hint_range(0.0, 1.0) = 0.25;
uniform float bloom_strength : hint_range(0.0, 1.0) = 0.12;
uniform float pixel_distortion : hint_range(0.0, 1.0) = 0.35;

// Added controls for screen depth: subtle reflection, specular highlight and fresnel
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.12;
uniform float reflection_gloss : hint_range(0.0, 64.0) = 8.0;
uniform float fresnel_power : hint_range(0.1, 8.0) = 2.0;
// glass_tint color for reflection simulation
uniform vec4 glass_tint = vec4(0.05, 0.06, 0.08, 1.0);

// Use built-in screen texture for compatibility

vec2 curve_screen(vec2 uv) {
    uv = uv * 2.0 - 1.0;  // Transform to -1 to 1 range
    vec2 offset = abs(uv.yx) / vec2(screen_curve, screen_curve);
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;  // Transform back to 0 to 1 range
    return uv;
}

vec3 phosphor_mask(vec2 uv) {
    // Get render target size in pixels from the screen texture
    ivec2 texSize = textureSize(SCREEN_TEXTURE, 0);
    vec2 res = vec2(texSize);
    // Map uv to pixel coordinates
    vec2 pixel_uv = uv * res;
    // Determine the subpixel column (R,G,B) using modulus of the integer X coordinate
    int col = int(mod(floor(pixel_uv.x), 3.0));
    vec3 mask = vec3(1.0);
    if (col == 0) {
        mask = vec3(1.0, 0.0, 0.0);
    } else if (col == 1) {
        mask = vec3(0.0, 1.0, 0.0);
    } else {
        mask = vec3(0.0, 0.0, 1.0);
    }
    return mix(vec3(1.0), mask, phosphor_strength);
}

vec3 simple_bloom(vec3 color, vec2 uv) {
    float lum = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 bloom_color = color * lum * bloom_strength;
    return color + bloom_color;
}

void fragment() {
    vec2 screen_uv = curve_screen(SCREEN_UV);

    // Add wobble effect
    screen_uv.x += sin(TIME * 3.0 + screen_uv.y * 50.0) * wobble_intensity;
    screen_uv.y += cos(TIME * 2.0 + screen_uv.x * 30.0) * wobble_intensity * 0.5;

    // Sample the screen texture
    vec3 color = texture(SCREEN_TEXTURE, screen_uv).rgb;

    // Apply chromatic aberration (always on for 1-bit CRT feel)
    vec2 chroma_offset = vec2(chromatic_aberration, 0.0);
    color.r = texture(SCREEN_TEXTURE, screen_uv + chroma_offset).r;
    color.g = texture(SCREEN_TEXTURE, screen_uv).g;
    color.b = texture(SCREEN_TEXTURE, screen_uv - chroma_offset).b;
    
    // Apply glitch effect (enhanced chromatic aberration)
    if (glitch_intensity > 0.0) {
        float glitch = glitch_intensity;
        vec2 offset = vec2(0.005 * glitch, 0.0);
    color.r = texture(SCREEN_TEXTURE, screen_uv + offset).r;
    color.b = texture(SCREEN_TEXTURE, screen_uv - offset).b;
    }
    
    // Pixel distortion (grid effect)
    if (pixel_distortion > 0.0) {
        vec2 pixel_uv = floor(screen_uv * 200.0) / 200.0;
        float pixel_noise = fract(sin(dot(pixel_uv, vec2(12.9898, 78.233))) * 43758.5453);
        color *= 1.0 - (pixel_noise * pixel_distortion * 0.1);
    }

    // Horizontal scanline mask using a smoothstep band per-line.
    // Convert screen_uv.y to pixel space using the screen texture size to get consistent thickness.
    ivec2 texSize = textureSize(SCREEN_TEXTURE, 0);
    float pixel_y = screen_uv.y * float(texSize.y);
    // Line index (which scanline we're on) based on desired count across the screen height
    float lines = max(1.0, scanline_count);
    float line_pos = floor((pixel_y / float(texSize.y)) * lines);
    // Center position of the current line in pixel space
    float line_center = (line_pos + 0.5) * (float(texSize.y) / lines);
    // Distance from the center of the line
    float dist = abs(pixel_y - line_center);
    // Smooth mask: 1.0 at center, falls to 0 over scan_thickness pixels
    float scan_mask = 1.0 - smoothstep(0.0, scan_thickness, dist) * scanline_intensity;
    color *= scan_mask;

    // Phosphor-inspired subtle glow between lines (softened)
    float glow = 1.0 - smoothstep(0.0, scan_thickness * 1.6, dist) * 0.35;
    color *= glow;

    // Add horizontal scanline roll with more flicker
    float roll = sin(TIME * 0.5 + screen_uv.y * 2.0) * 0.03;
    float flicker = sin(TIME * 30.0) * 0.02;
    color *= 1.0 + roll + flicker;

    // Apply vignette
    vec2 vignetteUV = SCREEN_UV;
    vignetteUV *= 1.0 - vignetteUV.yx;
    float vignette = vignetteUV.x * vignetteUV.y * 15.0;
    vignette = pow(vignette, vignette_strength);

    // Apply brightness and vignette
    color *= brightness * vignette;

    // Apply phosphor mask
    color *= phosphor_mask(SCREEN_UV);

    // Apply simple bloom / phosphor glow
    color = simple_bloom(color, SCREEN_UV);

    // Add subtle glossy reflection / fresnel to simulate glass screen depth
    // Approximate fresnel using distance from screen center (view angle proxy).
    vec2 center_uv = SCREEN_UV - 0.5;
    float center_dist = length(center_uv);
    // fresnel stronger at glancing angles (edges of the screen)
    float fresnel = pow(clamp(center_dist * 2.0, 0.0, 1.0), fresnel_power);
    fresnel = clamp(fresnel, 0.0, 1.0);

    // Simulate a blurred reflection highlight across the top-left area
    vec2 reflect_uv = SCREEN_UV;
    reflect_uv.x = reflect_uv.x * 0.6 + 0.15;
    reflect_uv.y = reflect_uv.y * 0.6 + 0.05;
    vec3 reflect_color = texture(SCREEN_TEXTURE, reflect_uv).rgb;
    // Mix with glass tint and use gloss to control sharpness
    float spec = pow(max(0.0, 1.0 - length(SCREEN_UV - vec2(0.2, 0.15)) * 3.0), reflection_gloss);
    vec3 reflection = mix(reflect_color, glass_tint.rgb, 0.5) * spec * reflection_strength;

    // Blend reflection using fresnel to bias edges and add a subtle sense of depth
    color = mix(color, color + reflection, fresnel * 0.75);

    // Ensure we're in bounds
    if (screen_uv.x < 0.0 || screen_uv.x > 1.0 || screen_uv.y < 0.0 || screen_uv.y > 1.0) {
        color = vec3(0.0);
    }

    COLOR = vec4(color, 1.0);
}