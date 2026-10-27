shader_type spatial;
render_mode cull_back, depth_prepass_alpha;

#include "res://shaders/toon_ramp.gdshaderinc"

uniform sampler2D atlas : source_color;
uniform int cols = 3;
uniform int rows = 3;
uniform int frame = 0;
uniform bool mirror_left = false;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.12;

// Anime faces are lit as one smooth surface: FaceAtlas sets where the face is and where it looks each frame, and
// the face's normals lean toward that direction, so a shadow band never cuts across the eyes, nose or mouth.
uniform vec3 face_center = vec3(0.0, -1000.0, 0.0);
uniform vec3 face_forward = vec3(0.0, 0.0, 1.0);
uniform float face_radius = 0.14;
varying float face_amount;
varying vec3 face_normal;

void vertex() {
    // The drawn features sit a hair in front of the skin, a little more at a distance, so they never flicker on it.
    vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    view.xyz += normalize(-view.xyz) * (0.0015 + 0.0008 * max(-view.z, 0.0));
    POSITION = PROJECTION_MATRIX * view;
}

void fragment() {
    int safe_cols = max(cols, 1);
    int safe_rows = max(rows, 1);
    int safe_frame = clamp(frame, 0, safe_cols * safe_rows - 1);
    int cell_x = safe_frame % safe_cols;
    int row_from_top = safe_frame / safe_cols;               // cell 0 is the atlas's top-left; UV.y runs down like the image
    float local_x = UV.x;
    if (mirror_left) {
        local_x = 1.0 - local_x;
    }
    vec2 atlas_uv = vec2((float(cell_x) + local_x) / float(safe_cols), (float(row_from_top) + UV.y) / float(safe_rows));
    vec4 color = texture(atlas, atlas_uv);
    if (color.a < alpha_cutoff) {
        discard;
    }
    ALBEDO = color.rgb;
    ALPHA = color.a;
    vec3 face_rel = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz - face_center;
    face_amount = (1.0 - smoothstep(face_radius * 0.75, face_radius, length(face_rel))) * smoothstep(-0.2, 0.4, dot(normalize(face_rel + face_forward * face_radius * 0.5), face_forward));   // front/back judged from inside the head
    face_normal = normalize((VIEW_MATRIX * vec4(face_forward, 0.0)).xyz);
}

void light() {
    float att = LIGHT_IS_DIRECTIONAL ? mix(ATTENUATION, 1.0, face_amount) : ATTENUATION;   // lit like the skin under it
    DIFFUSE_LIGHT += toon_diffuse(normalize(mix(NORMAL, face_normal, face_amount * 0.85)), LIGHT, att, LIGHT_COLOR, LIGHT_IS_DIRECTIONAL);
}
