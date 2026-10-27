// Shared anime light ramp for characters, the world and the face layers, so skin lights the same on all of them.
// Godot multiplies DIFFUSE_LIGHT by ALBEDO after the light pass, so the ramp is light only, never surface colour.
uniform vec4 shadow_color : source_color = vec4(0.42, 0.34, 0.5, 1.0);
uniform float band_1 : hint_range(0.0, 1.0) = 0.3;
uniform float band_2 : hint_range(0.0, 1.0) = 0.7;
uniform float band_mid : hint_range(0.0, 1.0) = 0.82;
uniform float band_softness : hint_range(0.0, 0.3) = 0.04;

// The key (directional) light paints two soft bands, its cast shadows fall into the dark band, and the unlit side
// takes the shadow tint. Fill and rim lights only add light where they reach, banded by angle, faded by distance.
vec3 toon_diffuse(vec3 normal, vec3 light, float attenuation, vec3 light_color, bool directional) {
    float ndl = max(dot(normalize(normal), normalize(light)), 0.0);
    float softness = max(band_softness, 0.0001); // smoothstep needs distinct edges, even for a hard band.
    if (!directional) {
        return light_color * smoothstep(band_1 - softness, band_1 + softness, ndl) * attenuation / PI;
    }
    float lit = ndl * max(attenuation, 0.0);
    float first = smoothstep(band_1 - softness, band_1 + softness, lit);
    float second = smoothstep(band_2 - softness, band_2 + softness, lit);
    return mix(mix(shadow_color.rgb, vec3(band_mid), first), vec3(1.0), second) * light_color / PI;
}
