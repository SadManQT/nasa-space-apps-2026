## M1-82: puts the dated Earth into an exterior's black sky. The spec comes from RoomContract.earth(room_id, scene_id)
## (a bundled JPL Horizons row in lola/sun_positions.json whose terrain-horizon check says Earth clears the local terrain);
## anything else leaves the sky black. Earth is drawn by the sky pass (sky_env_earth.gdshader) at its true angular size,
## lit from the dated Sun, so terrain in front hides it and its phase follows the row. Ambient and reflections keep the
## rig's settings (disabled on the Moon). Presentation only.
##   EarthSky.apply(world_environment.environment, RoomContract.earth("LOC-06", "EX-CH04-S09"), sun_energy)
extends RefCounted

const SHADER := preload("res://assets/environment/terrain/sky_env_earth.gdshader")

## Switches environment to a black sky carrying Earth. Returns false, and changes nothing, unless spec.presented.
static func apply(environment: Environment, spec: Dictionary, sun_energy: float = 6.0) -> bool:
	if environment == null or not bool(spec.get("presented", false)):
		return false
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("earth_dir", _vector(spec.direction))
	material.set_shader_parameter("earth_radius", deg_to_rad(float(spec.angular_diameter_deg) * 0.5))
	material.set_shader_parameter("sun_dir", _vector(spec.sun_direction))
	material.set_shader_parameter("sun_energy", sun_energy)
	var sky := Sky.new()
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	return true

## Back to the plain black sky (a scene whose row hides Earth, or no row).
static func clear(environment: Environment) -> void:
	if environment != null:
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color.BLACK
		environment.sky = null

static func _vector(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))
