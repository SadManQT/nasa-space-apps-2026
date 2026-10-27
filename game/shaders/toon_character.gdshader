shader_type spatial;
render_mode cull_back, depth_draw_opaque;

#include "res://shaders/toon_ramp.gdshaderinc"

uniform sampler2D base_texture : source_color;
uniform bool use_base_texture = false;
uniform sampler2D normal_texture : hint_normal;
uniform bool use_normal_texture = false;
uniform float normal_scale_value : hint_range(0.0, 2.0) = 1.0;
uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 rim_color : source_color = vec4(0.43, 0.72, 1.0, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.08;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform bool hair_specular = false;
uniform vec4 hair_specular_color : source_color = vec4(1.0, 0.92, 0.78, 1.0);
uniform float hair_specular_strength : hint_range(0.0, 2.0) = 0.28;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.72;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.0;

// Anime faces are lit as one smooth surface: FaceAtlas sets where the face is and where it looks each frame, and
// the face's normals lean toward that direction, so a shadow band never cuts across the eyes, nose or mouth.
uniform vec3 face_center = vec3(0.0, -1000.0, 0.0);
uniform vec3 face_forward = vec3(0.0, 0.0, 1.0);
uniform float face_radius = 0.14;
varying float face_amount;
varying vec3 face_normal;

void fragment() {
    vec4 color = base_color;
    if (use_base_texture) {
        color *= texture(base_texture, UV);
    }
    ALBEDO = color.rgb;
    ROUGHNESS = roughness_value;
    METALLIC = metallic_value;
    if (use_normal_texture) {
        NORMAL_MAP = texture(normal_texture, UV).rgb;
        NORMAL_MAP_DEPTH = normal_scale_value;
    }
    vec3 face_rel = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz - face_center;
    face_amount = (1.0 - smoothstep(face_radius * 0.75, face_radius, length(face_rel))) * smoothstep(-0.2, 0.4, dot(normalize(face_rel + face_forward * face_radius * 0.5), face_forward));   // front/back judged from inside the head
    face_normal = normalize((VIEW_MATRIX * vec4(face_forward, 0.0)).xyz);
    float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), rim_power) * (1.0 - face_amount);
    EMISSION = rim_color.rgb * rim * rim_strength;
}

void light() {
    vec3 n = normalize(mix(NORMAL, face_normal, face_amount * 0.85));
    // no sun shadow on the face: fringe and nose shadows would cut across the drawn features
    float att = LIGHT_IS_DIRECTIONAL ? mix(ATTENUATION, 1.0, face_amount) : ATTENUATION;
    DIFFUSE_LIGHT += toon_diffuse(n, LIGHT, att, LIGHT_COLOR, LIGHT_IS_DIRECTIONAL);
    if (hair_specular) {
        float highlight = pow(max(dot(reflect(-normalize(LIGHT), normalize(NORMAL)), normalize(VIEW)), 0.0), 24.0);
        float soft_band = smoothstep(0.18, 0.72, highlight) * max(ATTENUATION, 0.0);
        SPECULAR_LIGHT += hair_specular_color.rgb * soft_band * hair_specular_strength * LIGHT_COLOR / PI;
    }
}
