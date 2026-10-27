shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;

uniform vec4 rim_color : source_color = vec4(0.36, 0.65, 1.0, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.18;
uniform float rim_power : hint_range(0.5, 8.0) = 3.2;
uniform float rim_emission : hint_range(0.0, 4.0) = 0.65;

void fragment() {
    float facing = max(dot(normalize(NORMAL), normalize(VIEW)), 0.0);
    float rim = pow(1.0 - facing, rim_power);
    ALBEDO = rim_color.rgb;
    EMISSION = rim_color.rgb * rim * rim_emission;
    ALPHA = rim * rim_strength;
}
