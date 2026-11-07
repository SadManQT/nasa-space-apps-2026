// M3-8R (Sadman/claude, Claude Opus 5.5): a faint, sparse star field for lunar frames with no sunlit ground at all
// (ART_BIBLE §2 rule 12, Sadman 7 Nov 2026: "Faint stars there"), e.g. the dark relay road of EX-CH08-S03/S04.
// White points only: no Milky Way glow, no twinkling (nothing depends on TIME), no colour. Never used where a frame
// shows sunlit terrain, hardware or Earth's lit limb; earth_sky.gd decides that from the dated Horizons row.
// Target: Forward+ and Compatibility (sky shaders run in both). Budget: background pixels only, four hashes per
// pixel, no texture reads, no branches; radiance map 32 px (ambient and reflections stay disabled by the room rig).
shader_type sky;

group_uniforms stars;
/** Overall brightness of the brightest star (1.0 is a dark-adapted camera; a lit work area keeps them lower). */
uniform float star_intensity : hint_range(0.0, 2.0) = 1.0;
/** Fraction of grid cells that hold a star (sparse: well under one percent). */
uniform float star_density : hint_range(0.0, 0.05) = 0.006;
/** Cells per radian on the unit sphere; a star's position is jittered inside its cell. */
uniform float cells_per_radian : hint_range(50.0, 1000.0) = 260.0;
/** Angular radius of a star's anti-aliased core, in cells (about one pixel at a 70 deg view on 1080 lines). */
uniform float star_radius_cells : hint_range(0.05, 1.0) = 0.22;
/** Faintest-to-brightest spread: brightness = mix(faint_floor, 1, hash ^ magnitude_power). */
uniform float faint_floor : hint_range(0.0, 1.0) = 0.12;
uniform float magnitude_power : hint_range(1.0, 12.0) = 5.0;
group_uniforms;

// Offsets that decorrelate the four hashes taken from one cell (presence, jitter x/y/z, magnitude).
const vec3 JITTER_SEED_X = vec3(11.1, 3.7, 5.3);
const vec3 JITTER_SEED_Y = vec3(23.7, 7.1, 2.9);
const vec3 JITTER_SEED_Z = vec3(37.3, 1.9, 9.7);
const vec3 MAGNITUDE_SEED = vec3(5.3, 13.1, 17.9);

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	// A uniform 3D grid cut by the unit sphere gives evenly spread cells (no crowding at the zenith).
	vec3 grid = EYEDIR * cells_per_radian;
	vec3 cell = floor(grid);
	float present = step(1.0 - star_density, hash(cell));
	vec3 jitter = vec3(hash(cell + JITTER_SEED_X), hash(cell + JITTER_SEED_Y), hash(cell + JITTER_SEED_Z));
	vec3 star_dir = normalize(cell + 0.2 + 0.6 * jitter);
	// Small-angle distance from the view ray to the star, in cells.
	float offset = length(EYEDIR - star_dir * dot(EYEDIR, star_dir)) * cells_per_radian;
	float core = 1.0 - smoothstep(0.0, star_radius_cells, offset);
	float magnitude = mix(faint_floor, 1.0, pow(hash(cell + MAGNITUDE_SEED), magnitude_power));
	COLOR = vec3(present * core * magnitude * star_intensity);
}
