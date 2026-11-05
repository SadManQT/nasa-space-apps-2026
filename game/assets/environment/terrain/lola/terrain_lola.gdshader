// Lunar regolith on the LOLA terrain tiles (board M1-34). Exteriors have one hard Sun and no sky
// light (Art Bible section 2), so the terrain's look comes from three things:
//  - shape: an object-space normal map in the region's Godot frame on UV1 (written by
//    production/tools/build_terrain_tiles.py, curvature included), so every LOD shades the same and
//    the macro slope is never applied twice;
//  - regolith: the M1-35 kit's detail albedo and normal on UV2 (one repeat per 4 m), faded out with
//    distance so they never shimmer on far slopes;
//  - photometry: McEwen's lunar-Lambert function, I/F ~ (1 - L) mu0 + L 2 mu0 / (mu0 + mu), with
//    L(phase) from McEwen (1996), so sunlit ground has the flat, bright look of real lunar images
//    instead of a plain Lambert falloff at a grazing Sun. lunar_lambert = 0 gives plain Lambert.
// AO only darkens ambient light (Earthshine fill, if a scene adds it); the Sun is never multiplied
// by AO. The regolith detail is micro relief: when the Sun sits below the macro surface's own
// horizontal (a flat crest with the Sun at -1.5 deg, as at Aurora in April 2046) the neighbouring
// grains shadow every facet, so light() fades the detail term out over the last degree above the
// macro horizon instead of letting the detail normal sparkle through shadow-map stripes.
shader_type spatial;
render_mode specular_disabled;

varying vec3 macro_normal_view; // the LOLA + detail-crater normal in view space, before the regolith detail

uniform vec4 regolith_color : source_color = vec4(0.478, 0.463, 0.447, 1.0); // #7A7672, Art Bible regolith grey
uniform sampler2D normal_os : filter_linear_mipmap, repeat_disable;
uniform bool use_normal_os = true;
uniform sampler2D ao_map : hint_default_white, filter_linear_mipmap, repeat_disable;
uniform sampler2D detail_albedo : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool use_detail = true;
uniform float detail_mean = 0.161; // linear mean of detail_albedo: keeps the average colour at regolith_color
uniform float detail_strength : hint_range(0.0, 1.0) = 0.6;
uniform float detail_normal_strength : hint_range(0.0, 2.0) = 0.8;
uniform float detail_fade_start_m = 40.0;
uniform float detail_fade_end_m = 250.0;
uniform float lunar_lambert : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec3 n_obj = vec3(0.0, 1.0, 0.0);
	if (use_normal_os) {
		n_obj = normalize(texture(normal_os, UV).rgb * 2.0 - 1.0);
	}
	macro_normal_view = normalize((VIEW_MATRIX * (MODEL_MATRIX * vec4(n_obj, 0.0))).xyz);
	vec3 col = regolith_color.rgb;
	float fade = 1.0 - smoothstep(detail_fade_start_m, detail_fade_end_m, length(VERTEX));
	if (use_detail && fade > 0.0) {
		col *= mix(vec3(1.0), texture(detail_albedo, UV2).rgb / detail_mean, detail_strength * fade);
		vec2 dxy = (texture(detail_normal, UV2).rg * 2.0 - 1.0) * detail_normal_strength * fade;
		float dz = sqrt(max(1.0 - dot(dxy, dxy), 0.05));
		// tangent along +X, image-up along -Z (UV2 v grows toward +Z), both bent onto the macro normal
		vec3 t = normalize(vec3(1.0, 0.0, 0.0) - n_obj * n_obj.x);
		vec3 b = cross(n_obj, t);
		n_obj = normalize(t * dxy.x + b * dxy.y + n_obj * dz);
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	AO = texture(ao_map, UV).r;
	AO_LIGHT_AFFECT = 0.0;
	NORMAL = normalize((VIEW_MATRIX * (MODEL_MATRIX * vec4(n_obj, 0.0))).xyz);
}

void light() {
	// micro-relief self-shadowing: nothing on the patch is lit once the Sun is below the macro
	// surface's horizontal; the detail term fades in over the first degree (sin 1 deg = 0.0175)
	float above_macro_horizon = smoothstep(0.0, 0.0175, dot(macro_normal_view, LIGHT));
	float mu0 = dot(NORMAL, LIGHT) * above_macro_horizon;
	if (mu0 > 0.0) {
		float mu = max(dot(NORMAL, VIEW), 0.0);
		float phase = degrees(acos(clamp(dot(LIGHT, VIEW), -1.0, 1.0)));
		float l = clamp(1.0 + phase * (-0.019 + phase * (2.42e-4 - phase * 1.46e-6)), 0.0, 1.0) * lunar_lambert;
		float f = (1.0 - l) * mu0 + l * 2.0 * mu0 / max(mu0 + mu, 1e-3);
		DIFFUSE_LIGHT += f * ATTENUATION * LIGHT_COLOR / PI;
	}
}
