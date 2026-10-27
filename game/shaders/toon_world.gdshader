shader_type spatial;
render_mode cull_back, depth_draw_opaque;

#include "res://shaders/toon_ramp.gdshaderinc"

uniform sampler2D base_texture : source_color;
uniform bool use_base_texture = false;
uniform sampler2D normal_texture : hint_normal;
uniform bool use_normal_texture = false;
uniform float normal_scale_value : hint_range(0.0, 2.0) = 1.0;
uniform vec4 base_color : source_color = vec4(1.0);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.82;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.0;
// Cel flatten: the AI-made prop textures carry photoreal grime and scratches. Faint brightness noise is pulled to
// the brightness of its surroundings (a blurred mip); strong details (needles, keys, stripes) and all hue stay.
uniform float detail_flatten : hint_range(0.0, 1.0) = 0.85;
uniform float flatten_lod : hint_range(0.0, 8.0) = 4.0;

void fragment() {
    vec4 color = base_color;
    if (use_base_texture) {
        vec4 texel = texture(base_texture, UV);
        const vec3 LUMA = vec3(0.299, 0.587, 0.114);
        float sharp = dot(texel.rgb, LUMA);
        float soft = dot(textureLod(base_texture, UV, flatten_lod).rgb, LUMA);
        float weight = detail_flatten * (1.0 - smoothstep(0.08, 0.22, abs(sharp - soft)));
        texel.rgb = min(texel.rgb * mix(sharp, soft, weight) / max(sharp, 0.02), vec3(1.0));
        color *= texel;
    }
    ALBEDO = color.rgb;
    ROUGHNESS = roughness_value;
    METALLIC = metallic_value;
    if (use_normal_texture) {
        NORMAL_MAP = texture(normal_texture, UV).rgb;
        NORMAL_MAP_DEPTH = normal_scale_value;
    }
}

void light() {
    DIFFUSE_LIGHT += toon_diffuse(NORMAL, LIGHT, ATTENUATION, LIGHT_COLOR, LIGHT_IS_DIRECTIONAL);
}
