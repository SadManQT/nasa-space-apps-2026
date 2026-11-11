@tool
extends EditorPlugin

class RuntimeAssets extends EditorExportPlugin:
	func _get_name() -> String:
		return "LastLightRuntimeAssets"

	## GLBs that a scene or resource file loads as a PackedScene. Those need
	## their imported scene in the pack as well as the raw bytes.
	var _scene_glbs := {}

	func _export_begin(_features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
		_scene_glbs.clear()
		for root in ["res://scenes", "res://assets", "res://resources"]:
			_find_scene_glbs(root)
		_add_glbs("res://assets")

	func _find_scene_glbs(directory: String) -> void:
		for folder in DirAccess.get_directories_at(directory):
			_find_scene_glbs(directory.path_join(folder))
		for file in DirAccess.get_files_at(directory):
			if file.ends_with(".tscn") or file.ends_with(".tres"):
				var text := FileAccess.get_file_as_string(directory.path_join(file))
				var at := text.find(".glb\"")
				while at >= 0:
					var start := text.rfind("\"", at) + 1
					_scene_glbs[text.substr(start, at + 4 - start)] = true
					at = text.find(".glb\"", at + 4)

	func _add_glbs(directory: String) -> void:
		for folder in DirAccess.get_directories_at(directory):
			_add_glbs(directory.path_join(folder))
		for file in DirAccess.get_files_at(directory):
			if file.ends_with(".glb"):
				var path := directory.path_join(file)
				add_file(path, FileAccess.get_file_as_bytes(path), false)

	func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
		if path.ends_with(".glb") and not _scene_glbs.has(path):
			# The production loaders read glTF bytes, not an imported PackedScene.
			# Keep the raw file above and avoid a second imported scene payload,
			# unless a room or prop scene loads this GLB as a scene (M1-92 export check).
			skip()

var _exporter: RuntimeAssets

func _enter_tree() -> void:
	_exporter = RuntimeAssets.new()
	add_export_plugin(_exporter)

func _exit_tree() -> void:
	remove_export_plugin(_exporter)
