// M1-82 (Sadman/claude, Claude Opus 5.5): the dated Earth in the black lunar sky. Drawn by the sky pass, so every
// terrain mesh in front hides it and a real terrain horizon clips the disc exactly. Earth is a sphere at its true
// angular radius, lit from the dated Sun direction, so its phase follows the Sun-Earth elongation of the bundled JPL
// Horizons row. Everything else stays black (ART_BIBLE §2 rule 1). Blue ocean and white cloud bands only: no
// continents are invented on a disc about 30 px across. Set up by earth_sky.gd; never used without a dated row.
// Target: Forward+ and Compatibility (sky shaders run in both). Budget: background pixels only, one 5-octave value
// noise inside the disc only, no texture reads; radiance map 32 px (ambient and reflections stay disabled by the rig).
shader_type sky;

group_uniforms earth;
/** Unit direction from the observer to Earth's centre, in the room / site frame. */
uniform vec3 earth_dir = vec3(0.0, 0.0, -1.0);
/** Angular radius in radians: atan(6371 km / 384400 km) = 0.016573 (1.90 deg across). */
uniform float earth_radius : hint_range(0.001, 0.1) = 0.016573;
group_uniforms sun;
/** Unit direction from the observer to the Sun (the Sun is 389 times farther, so the same at Earth). */
uniform vec3 sun_dir = vec3(1.0, 0.0, 0.0);
/** The dated Sun light's energy, so the lit Earth matches the lit terrain. */
uniform float sun_energy : hint_range(0.0, 20.0) = 6.0;
group_uniforms surface;
/** Ocean and cloud albedo (mean Earth Bond albedo is about 0.3). */
uniform vec3 ocean_albedo : source_color = vec3(0.05, 0.13, 0.36);
uniform vec3 cloud_albedo : source_color = vec3(0.82, 0.84, 0.86);
/** Fraction of the radius over which the limb is anti-aliased. */
uniform float limb_softness : hint_range(0.0, 0.2) = 0.04;
group_uniforms;

const int CLOUD_OCTAVES = 5;
const vec3 CLOUD_STRETCH = vec3(3.0, 7.0, 3.0);  // bands along latitude
const vec3 CLOUD_OFFSET = vec3(1.7, 0.3, 2.9);

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float value_noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1.0, 0.0, 0.0)), f.x), mix(hash(i + vec3(0.0, 1.0, 0.0)), hash(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(hash(i + vec3(0.0, 0.0, 1.0)), hash(i + vec3(1.0, 0.0, 1.0)), f.x), mix(hash(i + vec3(0.0, 1.0, 1.0)), hash(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int octave = 0; octave < CLOUD_OCTAVES; octave++) {
		value += amplitude * value_noise(p);
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

void sky() {
	float along = dot(EYEDIR, earth_dir);
	// Offset from the disc centre in the tangent plane: 0 at the centre, 1 at the limb, > 1 outside.
	float s = length(EYEDIR - earth_dir * along) / sin(earth_radius);
	vec3 tangent = (EYEDIR - earth_dir * along) / sin(earth_radius);
	// Outward normal of the hemisphere that faces the Moon (only used inside the disc).
	vec3 normal = normalize(tangent - earth_dir * sqrt(max(1.0 - s * s, 0.0)));
	float lit = max(dot(normal, sun_dir), 0.0);
	float clouds = 0.0;
	// The one branch: the disc covers a few hundred pixels, so the test is coherent across every other sky pixel
	// and keeps the noise off the rest of the background (cheaper than computing it everywhere and masking).
	if (s < 1.0) {
		clouds = smoothstep(0.52, 0.72, fbm(normal * CLOUD_STRETCH + CLOUD_OFFSET));
	}
	vec3 albedo = mix(ocean_albedo, cloud_albedo, clouds);
	// Inside the disc and on the observer's side of the sky (along > 0); black everywhere else.
	float disc = smoothstep(1.0, 1.0 - limb_softness, s) * step(0.0, along);
	COLOR = albedo * lit * sun_energy * disc;
}
