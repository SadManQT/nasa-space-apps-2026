extends RefCounted

## Give user:// a unique name before any production scene exists. Explicit
## slot injection keeps disk IO in the OS temp directory, including in a
## workspace sandbox where the platform's application-data directory is read-only.
var original_user_dir := ""
var directory := ""
var path := ""
var legacy_path := ""

func setup(label: String) -> bool:
	original_user_dir = OS.get_user_data_dir()
	var name := "lla-%s-%d-%d" % [label, OS.get_process_id(), Time.get_ticks_usec()]
	ProjectSettings.set_setting("application/config/use_custom_user_dir", true)
	ProjectSettings.set_setting("application/config/custom_user_dir_name", "LastLightAcademy-tests/" + name)
	directory = OS.get_temp_dir().path_join(name)
	path = directory.path_join("last_light_expedition_v2.json")
	legacy_path = directory.path_join("last_light_expedition.json")
	return OS.get_user_data_dir() != original_user_dir and DirAccess.make_dir_recursive_absolute(directory) == OK

## Forward+ initializes relative cache paths before setup changes user://.
## Recreate their parents only; never copy cache files or player data.
func prepare_rendering_cache() -> bool:
	return _prepare_cache_directories(original_user_dir.path_join("shader_cache"), OS.get_user_data_dir().path_join("shader_cache"))

func _prepare_cache_directories(source: String, target: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(target) != OK:
		return false
	for child in DirAccess.get_directories_at(source):
		if not _prepare_cache_directories(source.path_join(child), target.path_join(child)):
			return false
	return true

func configure(node: Node) -> void:
	node.set("save_path", path)
	if node.get_script() == preload("res://scripts/main.gd"):
		node.set("legacy_save_path", legacy_path)

func cleanup() -> void:
	preload("res://scripts/save/save_service.gd").new().clear(path)
	preload("res://scripts/save/legacy_save.gd").clear_save(legacy_path)
	DirAccess.remove_absolute(directory)
