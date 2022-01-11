tool
extends Control

enum State { PAN, DRAW, ERASE }

const INTERNAL_TEXTURE_FLAGS = 0

export(ImageTexture) var image_texture = null

var is_standalone = true

var _actual_texture = null
var _image_size = null
var _zoom = 1
var _dragging = false
var _drawing_reference_pos = null
var _erasing_reference_pos = null
var _state = null

onready var _texture_rect = find_node("TextureRect")
onready var _scroll_container = find_node("ScrollContainer")
onready var _zoom_label = find_node("ZoomLabel")
onready var _pan_button = find_node("PanButton")
onready var _draw_button = find_node("DrawButton")
onready var _erase_button = find_node("EraseButton")
onready var _color_picker = find_node("ColorPickerButton")
onready var _panel = find_node("Panel")


func _ready():
	if Engine.editor_hint and is_standalone:
		return
	_image_size = image_texture.get_size()
	assert(_image_size != Vector2.ZERO)
	_pan_button.connect("pressed", self, "_change_state", [State.PAN])
	_draw_button.connect("pressed", self, "_change_state", [State.DRAW])
	_erase_button.connect("pressed", self, "_change_state", [State.ERASE])
	_texture_rect.connect("gui_input", self, "_on_texture_rect_gui_input")
	_panel.connect("gui_input", self, "_on_panel_gui_input")
	_change_state(State.PAN)
	_actual_texture = ImageTexture.new()
	_actual_texture.create_from_image(image_texture.get_data(), INTERNAL_TEXTURE_FLAGS)
	_texture_rect.texture = _actual_texture
	_update_zoom_label()


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
	if (
		pixel_position.x < 0
		or pixel_position.x >= _image_size.x
		or pixel_position.y < 0
		or pixel_position.y >= _image_size.y
	):
		return
	var image = _actual_texture.get_data()
	image.lock()
	image.set_pixelv(pixel_position, color)
	image.unlock()
	image_texture.set_data(image)
	_actual_texture.set_data(image)
	image_texture.emit_changed()
	_actual_texture.emit_changed()
	# editor_interface.save_scene()  # TODO: consider forcing save


func _draw_at_pos(event_position):
	var pixel_position = _event_position_to_pixel_position(event_position)
	_fill_pixel(pixel_position, _color_picker.color)


func _erase_at_pos(event_position):
	var pixel_position = _event_position_to_pixel_position(event_position)
	_fill_pixel(pixel_position, Color.transparent)


func _try_handling_motion_events(event):
	if not event is InputEventMouseMotion:
		return
	if _dragging:
		_scroll_container.scroll_horizontal -= event.relative.x
		_scroll_container.scroll_vertical -= event.relative.y
	elif _drawing_reference_pos != null:
		_drawing_reference_pos += event.relative
		_draw_at_pos(_drawing_reference_pos)
	elif _erasing_reference_pos != null:
		_erasing_reference_pos += event.relative
		_erase_at_pos(_erasing_reference_pos)


func _try_handling_zoom_events(event):
	if (
		not event is InputEventMouseButton
		or not event.is_pressed()
		or not event.button_index in [BUTTON_WHEEL_UP, BUTTON_WHEEL_DOWN]
	):
		return
	_zoom = max(1, _zoom + (1 if event.button_index == BUTTON_WHEEL_UP else -1))
	_texture_rect.rect_min_size = _image_size * _zoom
	_texture_rect.rect_size = _texture_rect.rect_min_size
	_texture_rect.material.set_shader_param("zoom", _zoom)
	_update_zoom_label()


func _on_texture_rect_gui_input(event):
	# TODO: refactor (extract)
	_try_handling_motion_events(event)
	if not event is InputEventMouseButton:
		return
	if event.is_pressed() and event.button_index == BUTTON_LEFT:
		if _state == State.PAN:
			_dragging = true
		elif _state == State.DRAW:
			_draw_at_pos(event.position)
			_drawing_reference_pos = event.position
		elif _state == State.ERASE:
			_erase_at_pos(event.position)
			_erasing_reference_pos = event.position
	elif not event.is_pressed() and event.button_index == BUTTON_LEFT:
		if _state == State.PAN:
			_dragging = false
		elif _state == State.DRAW:
			_drawing_reference_pos = null
		elif _state == State.ERASE:
			_erasing_reference_pos = null
	elif event.is_pressed() and event.button_index == BUTTON_MIDDLE:
		_dragging = true
	elif not event.is_pressed() and event.button_index == BUTTON_MIDDLE:
		_dragging = false
	_try_handling_zoom_events(event)
	get_tree().set_input_as_handled()


func _on_panel_gui_input(event):
	_try_handling_zoom_events(event)
