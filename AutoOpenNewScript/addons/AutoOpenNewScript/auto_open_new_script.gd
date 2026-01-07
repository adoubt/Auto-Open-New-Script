@tool
extends EditorPlugin

var fs := EditorInterface.get_resource_filesystem()
var known_files := {}

func _enter_tree() -> void:
	_cache_existing_files()
	fs.filesystem_changed.connect(_on_filesystem_changed)

func _exit_tree() -> void:
	if fs.filesystem_changed.is_connected(_on_filesystem_changed):
		fs.filesystem_changed.disconnect(_on_filesystem_changed)

func _cache_existing_files() -> void:
	known_files.clear()
	_scan_dir("res://")

func _scan_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	while true:
		var file := dir.get_next()
		if file == "":
			break
		if file.begins_with("."):
			continue

		var full_path := path + "/" + file
		if dir.current_is_dir():
			_scan_dir(full_path)
		else:
			known_files[full_path] = true
	dir.list_dir_end()

func _on_filesystem_changed() -> void:
	_check_for_new_scripts("res://")

func _check_for_new_scripts(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	while true:
		var file := dir.get_next()
		if file == "":
			break
		if file.begins_with("."):
			continue

		var full_path := path + "/" + file
		if dir.current_is_dir():
			_check_for_new_scripts(full_path)
		else:
			if not known_files.has(full_path) and file.ends_with(".gd"):
				known_files[full_path] = true
				_open_script(full_path)
	dir.list_dir_end()

func _open_script(path: String) -> void:
	var script := load(path)
	if script:
		EditorInterface.edit_resource(script)
