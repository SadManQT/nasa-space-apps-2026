@tool
extends EditorPlugin

class RuntimeAssets extends EditorExportPlugin:
	func _get_name() -> String:
		return "LastLightRuntimeAssets"

	func _export_begin(_features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
		_add_glbs("res://assets")

	func _add_glbs(directory: String) -> void:
		for folder in DirAccess.get_directories_at(directory):
			_add_glbs(directory.path_join(folder))
		for file in DirAccess.get_files_at(directory):
			if file.ends_with(".glb"):
				var path := directory.path_join(file)
				add_file(path, FileAccess.get_file_as_bytes(path), false)

	func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
		if path.ends_with(".glb"):
			# The production loaders read glTF bytes, not an imported PackedScene.
			# Keep the raw file above and avoid a second imported scene payload.
			skip()

var _exporter: RuntimeAssets

func _enter_tree() -> void:
	_exporter = RuntimeAssets.new()
	add_export_plugin(_exporter)

func _exit_tree() -> void:
	remove_export_plugin(_exporter)
