tool
extends EditorPlugin

const ImageEditor = preload("res://addons/godot-image-editor-plugin/ImageEditor.tscn")

var _image_editor_root = null


func _enter_tree():
	_image_editor_root = ImageEditor.instance()
	_image_editor_root.editor_interface = get_editor_interface()
	add_control_to_bottom_panel(_image_editor_root, "Image Editor")
	connect('scene_changed', self, '_on_scene_changed')
	
	
func _on_scene_changed(node):
	print('_on_scene_changed ', node)


func _exit_tree():
	remove_control_from_bottom_panel(_image_editor_root)
	_image_editor_root = null
	disconnect('scene_changed', self, '_on_scene_changed')
