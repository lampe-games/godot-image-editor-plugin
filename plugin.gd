tool
extends EditorPlugin

const ImageEditor = preload("res://addons/godot-image-editor-plugin/ImageEditor.tscn")

var _image_editor_root = null


func _enter_tree():
	var editor_interface = get_editor_interface()
	var editor_inspector = editor_interface.get_inspector()
	editor_inspector.connect("resource_selected", self, "_on_resource_selected")
	var editor_selection = editor_interface.get_selection()
	editor_selection.connect("selection_changed", self, "_on_selection_changed")


func _exit_tree():
	_close_image_editor()


func _open_image_editor(image_texture):
	if _image_editor_root != null:
		_close_image_editor()
	_image_editor_root = ImageEditor.instance()
	_image_editor_root.image_texture = image_texture
	_image_editor_root.is_standalone = false
	add_control_to_bottom_panel(_image_editor_root, "Image Editor")


func _close_image_editor():
	if _image_editor_root == null:
		return
	remove_control_from_bottom_panel(_image_editor_root)
	# TODO: make sure we don't need to free
	_image_editor_root = null


func _on_resource_selected(resource, _property):
	"""triggered when "Edit" pressed on resource - opens resource in inspector"""
	if resource is ImageTexture:
		_open_image_editor(resource)


func _on_selection_changed():
	"""triggered when node(s) selected in Editor's SceneTree - opens something else in inspector"""
	_close_image_editor()
