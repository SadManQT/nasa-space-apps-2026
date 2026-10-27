shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform sampler2D base_texture : source_color;
uniform bool use_base_texture = false;
uniform vec4 base_color : source_color = vec4(0.12, 0.08, 0.18, 1.0);
uniform float outline_width : hint_range(0.0001, 0.04) = 0.006;
uniform float outline_darkness : hint_range(0.0, 1.0) = 0.58;

void vertex() {
    vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    vec3 view_normal = MODELVIEW_NORMAL_MATRIX * NORMAL;
    vec2 direction = (PROJECTION_MATRIX * vec4(view_normal, 0.0)).xy * VIEWPORT_SIZE;
    POSITION = PROJECTION_MATRIX * view_position;
    // Width is a fraction of viewport height, for perspective and orthographic cameras.
    POSITION.xy += direction / max(length(direction), 1e-5) * vec2(VIEWPORT_SIZE.y / VIEWPORT_SIZE.x, 1.0) * outline_width * POSITION.w;
    vec4 behind = PROJECTION_MATRIX * (view_position - vec4(0.0, 0.0, outline_width * max(abs(view_position.z), 0.1), 0.0));
    POSITION.z = behind.z / behind.w * POSITION.w;
}

void fragment() {
    vec3 color = base_color.rgb;
    if (use_base_texture) {
        color *= texture(base_texture, UV).rgb;
    }
    ALBEDO = mix(color, vec3(0.025, 0.018, 0.04), outline_darkness);
}
