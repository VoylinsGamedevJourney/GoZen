extends Node

signal _on_open_project_settings

signal _on_project_loaded
signal _on_unsaved_changes
signal _on_saved

signal _on_title_changed(new_title)
signal _on_resolution_changed(new_resolution)
signal _on_file_added(new_file)


const PATH_RECENT_PROJECTS := "user://recent_projects"


var project: Project:
	set(x):
		project = x
		_on_project_loaded.emit()
var explorer: Control


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("save_project"):
		save_project()


func load_project(project_path: String) -> void:
	var data: String = FileManager.load_data(get_full_project_path())
	if data != "": # TODO: Improve this check (sometimes data is invalid but not "")
		project = str_to_var(data)
	print("Project not at path: '%s'" % project_path)
	erase_recent_project(project_path)
	return


func save_project() -> void:
	if project == null:
		return # No project here so nothing to save
	if project.path != "": # Existing project
		FileManager.save_data(project, get_full_project_path())
	# New project
	explorer = ModuleManager.get_selected_module("file_explorer")
	explorer.create("Save project", FileExplorer.MODE.SAVE_PROJECT)
	explorer._on_save_project_path_selected.connect(_on_new_project_path_selected)
	explorer._on_cancel_pressed.connect(_explorer_cancel_pressed)
	get_tree().current_scene.find_child("Content").add_child(explorer)
	explorer.open()


func _on_new_project_path_selected(new_path: String) -> void:
	project.title = new_path.split("/")[-1].replace(".gozen",'')
	project.path = new_path.replace("%s.gozen" % project.title, '')
	add_recent_project(project.path)
	save_project()


func _explorer_cancel_pressed() -> void:
	explorer = null


##############################################################
# Recent Projects  ###########################################
##############################################################

func get_recent_projects() -> Array:
	if !FileAccess.file_exists(PATH_RECENT_PROJECTS):
		FileManager.save_data([], PATH_RECENT_PROJECTS)
	return str_to_var(FileManager.load_data(PATH_RECENT_PROJECTS))


func add_recent_project(project_path: String) -> void:
	var recent_projects: Array = [project_path]
	var old_recent_projects := get_recent_projects()
	old_recent_projects.erase(project_path)
	recent_projects.append_array(old_recent_projects)
	FileManager.save_data(recent_projects, PATH_RECENT_PROJECTS)


func erase_recent_project(project_path: String) -> void:
	var recent_projects := get_recent_projects()
	recent_projects.erase(project_path)
	FileManager.save_data(recent_projects, PATH_RECENT_PROJECTS)


##############################################################
# Getters and setters  #######################################
##############################################################

# TITLE  #####################################################

func get_title() -> String:
	return project.title


func set_title(new_title: String) -> void:
	# TODO: Remove invalid chars
	project.title = new_title
	ProjectManager._on_title_change.emit(new_title)


# PATH  ######################################################

func get_project_path() -> String:
	return project.path


func get_full_project_path() -> String:
	return "%s/%s.gozen" % [project.path, project.title]


func set_project_path(new_path: String) -> void:
	# If new_path is "", it means the project will try to save under a new path
	# Todo: Make certain new_path is not full path
	project.path = new_path


# RESOLUTION  ################################################

func get_resolution() -> Vector2i:
	return project.resolution


func set_resolution(new_resolution: Vector2i) -> void:
	project.resolution = new_resolution
	_on_resolution_changed.emit(new_resolution)


# FILES  #####################################################

func get_files() -> Dictionary:
	return project.files


func get_file(id: int) -> File:
	return project.files[id]


func add_file(new_file: File) -> void:
	project.files[project.files_id] = new_file
	project.files_id += 1
	_on_file_added.emit(new_file)
