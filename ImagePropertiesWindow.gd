tool
extends WindowDialog

signal image_properties_changed(image)

export(Resource) var image = null

var is_standalone = true

onready var _ok_button = find_node("OkButton")
onready var _cancel_button = find_node("CancelButton")
onready var _width_control = find_node("WidthSpinBox")
onready var _height_control = find_node("HeightSpinBox")


func _ready():
	yield(get_tree(), "idle_frame")  # wait for is_standalone sync
	if Engine.editor_hint and is_standalone:
		return
	self.connect("about_to_show", self, "_on_about_to_show")
	_ok_button.connect("pressed", self, "_on_ok_button_pressed")
	_cancel_button.connect("pressed", self, "hide")


func _emit_new_image():
	var new_width = _width_control.value
	var new_height = _height_control.value
	var image_to_emit = image
	if image_to_emit == null:
		var new_mipmaps = false
		var new_format = Image.FORMAT_RGBA8
		image_to_emit = Image.new()
		image_to_emit.create(new_width, new_height, new_mipmaps, new_format)
	else:
		image_to_emit.crop(new_width, new_height)
	emit_signal("image_properties_changed", image_to_emit)


func _on_about_to_show():
	if image == null:
		return
	_width_control.value = image.get_size().x
	_height_control.value = image.get_size().y


func _on_ok_button_pressed():
	hide()
	if (
		image == null
		or _width_control.value != image.get_size().x
		or _height_control.value != image.get_size().y
	):
		_emit_new_image()
