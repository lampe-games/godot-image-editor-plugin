tool
extends Control

enum State { PAN, DRAW, ERASE }

export(ImageTexture) var image_texture = null

var is_standalone = true

var _image_size = null
var _zoom = 1
var _dragging = false
var _state = null

onready var _texture_rect = find_node("TextureRect")
onready var _scroll_container = find_node("ScrollContainer")
onready var _zoom_label = find_node("Label")
onready var _pan_button = find_node("PanButton")
onready var _draw_button = find_node("DrawButton")
onready var _erase_button = find_node("EraseButton")
onready var _color_picker = find_node("ColorPickerButton")


func _ready():
	if Engine.editor_hint and is_standalone:
		return
	assert(_image_size != Vector2.ZERO)
	_pan_button.connect("pressed", self, "_change_state", [State.PAN])
	_draw_button.connect("pressed", self, "_change_state", [State.DRAW])
	_erase_button.connect("pressed", self, "_change_state", [State.ERASE])
	_change_state(State.PAN)
	_update_zoom_label()
	_texture_rect.texture = image_texture  # TODO: create new texture to clear flags
	_image_size = image_texture.get_size()


func _change_state(new_state):
	var state_to_button_mapping = {
		State.PAN: _pan_button,
		State.DRAW: _draw_button,
		State.ERASE: _erase_button,
	}

	if _state in state_to_button_mapping:
		state_to_button_mapping[_state].find_node("Overlay").hide()

	_state = new_state

	if _state in state_to_button_mapping:
		state_to_button_mapping[_state].find_node("Overlay").show()


func _update_zoom_label():
	_zoom_label.text = "Zoom: {0}".format([_zoom])


func _event_position_to_pixel_position(event_position):
	return (event_position / _zoom).floor()


func _fill_pixel(pixel_position, color):
	var image = image_texture.get_data()  # TODO: use _actual_texture
	image.lock()
	image.set_pixelv(pixel_position, color)
	image.unlock()
	image_texture.set_data(image)  # TODO: use _actual_texture
	image_texture.emit_changed()  # TODO: use _actual_texture
	# editor_interface.save_scene()  # TODO: consider forcing save


func _draw_at_pos(event_position):
	var pixel_position = _event_position_to_pixel_position(event_position)
	_fill_pixel(pixel_position, _color_picker.color)


func _erase_at_pos(event_position):
	var pixel_position = _event_position_to_pixel_position(event_position)
	_fill_pixel(pixel_position, Color.transparent)


func _on_texture_rect_gui_input(event):
	# TODO: refactor (extract)
	if event is InputEventMouseMotion and _dragging:
		_scroll_container.scroll_horizontal -= event.relative.x
		_scroll_container.scroll_vertical -= event.relative.y
		return
	if not event is InputEventMouseButton:
		return
	if event.is_pressed() and event.button_index == BUTTON_LEFT:
		if _state == State.PAN:
			_dragging = true
		elif _state == State.DRAW:
			_draw_at_pos(event.position)
		elif _state == State.ERASE:
			_erase_at_pos(event.position)
	elif not event.is_pressed() and event.button_index == BUTTON_LEFT:
		if _state == State.PAN:
			_dragging = false
	elif event.is_pressed() and event.button_index == BUTTON_WHEEL_UP:
		_zoom += 1
		_texture_rect.rect_size = _image_size * _zoom
		_texture_rect.rect_min_size = _texture_rect.rect_size
		_texture_rect.material.set_shader_param("zoom", _zoom)
		_update_zoom_label()
	elif event.is_pressed() and event.button_index == BUTTON_WHEEL_DOWN:
		_zoom = max(1, _zoom - 1)
		_texture_rect.rect_min_size = _image_size * _zoom
		_texture_rect.rect_size = _texture_rect.rect_min_size
		_texture_rect.material.set_shader_param("zoom", _zoom)
		_update_zoom_label()
	elif event.is_pressed() and event.button_index == BUTTON_MIDDLE:
		_dragging = true
	elif not event.is_pressed() and event.button_index == BUTTON_MIDDLE:
		_dragging = false
	get_tree().set_input_as_handled()
