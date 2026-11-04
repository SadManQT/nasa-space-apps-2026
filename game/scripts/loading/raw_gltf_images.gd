## Decode and mip CPU Images before GLTF creates/uploads their textures.
## Registered once, but participates only in our explicitly tagged raw states.
extends GLTFDocumentExtension

func _import_preflight(state: GLTFState, _extensions: PackedStringArray) -> Error:
	return OK if state.get_meta("threaded_raw", false) else ERR_SKIP

func _parse_image_data(state: GLTFState, data: PackedByteArray, mime: String, image: Image) -> Error:
	var error := ERR_UNAVAILABLE
	if mime == "image/png" or (data.size() > 4 and data[0] == 137):
		error = image.load_png_from_buffer(data)
	elif mime == "image/jpeg" or (data.size() > 2 and data[0] == 255):
		error = image.load_jpg_from_buffer(data)
	if error != OK:
		return OK # Leave unsupported images to Godot's default decoder.
	var start := Time.get_ticks_usec()
	if not image.has_mipmaps():
		image.generate_mipmaps()
	state.set_meta("mipmaps_usec", int(state.get_meta("mipmaps_usec", 0)) + Time.get_ticks_usec() - start)
	return OK

func _get_image_file_extension() -> String:
	return ".png" # Embedded-only state; no extracted files are written.
