extends Control


func _ready() -> void:
	add_child(ModuleManager.get_module("editor"))
	add_child(ModuleManager.get_module("startup"))
	add_child(ModuleManager.get_module("command_bar"))