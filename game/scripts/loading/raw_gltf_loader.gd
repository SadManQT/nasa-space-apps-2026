## Resource-only half of the approved raw GLB pipeline. Never creates Nodes.
## A virtual suffix bypasses editor remapping to a differently imported scene.
extends ResourceFormatLoader

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["lla_gltf"])

func _get_resource_type(path: String) -> String:
	return "GLTFState" if path.ends_with(".lla_gltf") else ""

func _handles_type(type: StringName) -> bool:
	return type == &"GLTFState"

func _exists(path: String) -> bool:
	return FileAccess.file_exists(path.trim_suffix(".lla_gltf"))

func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
	var source := path.trim_suffix(".lla_gltf")
	var start := Time.get_ticks_usec()
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	state.set_meta("threaded_raw", true)
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var error := document.append_from_file(source, state)
	if error != OK:
		return error
	# generate_scene must use this document: append selects its mesh-conversion
	# extensions. A fresh document silently omits ImporterMesh conversions.
	state.set_meta("raw_document", document)
	var mipmaps_ms := int(state.get_meta("mipmaps_usec", 0)) / 1000.0
	state.set_meta("decode_ms", (Time.get_ticks_usec() - start) / 1000.0 - mipmaps_ms)
	# Images already include CPU-generated mips before their first upload.
	# No texture.get_image() / GPU readback or texture replacement on workers.
	for material in state.get_materials():
		if material is StandardMaterial3D:
			if material.albedo_texture != null:
				material.albedo_texture.set_meta(&"mipmaps_ready", true)
			if material.normal_enabled and material.normal_texture != null:
				material.normal_texture.set_meta(&"mipmaps_ready", true)
	state.set_meta("mipmaps_ms", mipmaps_ms)
	return state
