// M3-6A: the filtered remote camera's picture of the 12 January 2047 eclipse as seen from the Moon (EX-CH06-S07).
// The camera tracks the Sun, so the Sun stays centred while Earth's much larger dark disc crosses it. At totality
// the Sun is hidden and only Earth's atmospheric rim is lit: refracted, reddened sunlight, brightest on the side
// nearest the hidden Sun. Black sky, no stars, no atmosphere glow around the Sun (vacuum), no geography on Earth.
// eclipse_monitor_screen.gd computes the geometry and the auto-exposure gain and sets the uniforms.
shader_type canvas_item;

uniform vec2 frame_size = vec2(1152.0, 648.0);
uniform vec2 sun_center = vec2(0.0, 0.0);      // frame units: (0,0) is the centre, 1.0 is the frame height
uniform float sun_radius = 0.0857;
uniform vec2 earth_center = vec2(0.6, 0.1);
uniform float earth_radius = 0.30;
uniform float ring_width = 0.0036;
uniform float gain = 1.0;                       // auto exposure: rises as the visible Sun shrinks
uniform bool filter_in = true;
uniform float noise_time = 0.0;                 // frozen while the frame is held

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = (UV - 0.5) * vec2(frame_size.x / frame_size.y, 1.0);
	vec3 colour = vec3(0.0);
	float px = 1.0 / frame_size.y;

	// Sun: limb-darkened disc, neutral through a metallised solar filter
	float ds = length(p - sun_center);
	float mu = sqrt(max(1.0 - pow(ds / sun_radius, 2.0), 0.0));
	vec3 sun_tint = filter_in ? vec3(1.0, 0.95, 0.86) : vec3(1.0, 0.98, 0.94);
	float sun = (0.42 + 0.58 * mu) * smoothstep(sun_radius + px, sun_radius - px, ds);

	// Earth: the night side faces the Moon, so the disc is near-black and featureless
	float de = length(p - earth_center);
	float earth = smoothstep(earth_radius + px, earth_radius - px, de);

	// the refracted rim: a thin band just outside the solid Earth, weighted towards the Sun's direction
	vec2 n = (p - earth_center) / max(de, 1e-5);
	vec2 to_sun = sun_center - earth_center;
	float off = length(to_sun);
	float facing = off > 1e-5 ? max(dot(n, to_sun / off), 0.0) : 1.0;
	float spread = clamp(off / earth_radius, 0.0, 1.0);
	float azimuth = mix(1.0, 0.18 + 0.82 * pow(facing, 1.6), spread);
	float outside = smoothstep(earth_radius - 2.0 * px, earth_radius + px, de);
	float band = exp(-pow((de - earth_radius * 1.004) / ring_width, 2.0)) * outside;
	float bloom = exp(-pow(max(de - earth_radius, 0.0) / (ring_width * 5.0), 1.4)) * outside;   // lens bloom at high gain
	vec3 rim = (mix(vec3(0.62, 0.08, 0.03), vec3(1.0, 0.46, 0.16), band) * band + vec3(0.5, 0.1, 0.035) * bloom * 0.3) * azimuth * 0.16;

	colour = sun_tint * sun * (1.0 - earth);
	colour = min(colour, vec3(1.0));
	colour += rim * gain;
	colour += vec3(0.010, 0.012, 0.016) * earth * min(gain, 3.0) * 0.12;

	// sensor noise, a hint of vignette and scan texture so it reads as an instrument picture
	float grain = (hash(floor(UV * frame_size) + floor(noise_time * 24.0)) - 0.5) * 0.018 * (0.6 + 0.4 * min(gain, 4.0));
	colour += vec3(grain);
	float vignette = 1.0 - 0.22 * pow(length(UV - 0.5) * 1.3, 2.4);
	colour *= vignette;
	COLOR = vec4(clamp(colour, 0.0, 1.0), 1.0);
}
