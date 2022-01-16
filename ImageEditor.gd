tool
extends Control

enum State { PAN, DRAW, ERASE }

const INTERNAL_TEXTURE_FLAGS = 0
const RECT_MARGIN_FOR_INITIAL_ZOOM = 10

export(ImageTexture) var image_texture = null

var is_standalone = true

var _local_texture = null
var _image = null
var _zoom = 1
var _zoom_altered = false
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
onready var _properties_button = find_node("PropertiesButton")
onready var _properties_window = find_node("ImagePropertiesWindow")
onready var _panel = find_node("Panel")
onready var _stats_label = find_node("StatsLabel")


func _ready():
	if Engine.editor_hint and is_standalone:
		return
	_properties_window.is_standalone = false
	if image_texture.get_size() == Vector2.ZERO or image_texture.get_data() == null:
		return
	_pan_button.connect("pressed", self, "_change_state", [State.PAN])
	_draw_button.connect("pressed", self, "_change_state", [State.DRAW])
	_erase_button.connect("pressed", self, "_change_state", [State.ERASE])
	_properties_button.connect("pressed", self, "_on_properties_button_pressed")
	_texture_rect.connect("gui_input", self, "_on_texture_rect_gui_input")
	_panel.connect("gui_input", self, "_on_panel_gui_input")
	_panel.connect("resized", self, "_on_panel_resized")
	_properties_window.connect("image_properties_changed", self, "_on_image_properties_changed")
	_change_state(State.PAN)
	_setup_local_texture()
	_update_zoom_label()
	_update_stats_label()


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


func _setup_local_texture():
	_local_texture = ImageTexture.new()
	_image = image_texture.get_data()
	_local_texture.create_from_image(_image, INTERNAL_TEXTURE_FLAGS)
	_texture_rect.texture = _local_texture


func _update_zoom_label():
	_zoom_label.text = "Zoom: {0}".format([_zoom])


func _update_stats_label():
	var image = _local_texture.get_data()
	var image_size = image.get_size()
	var image_format_to_str_mapping = {
		0: "L8",
		1: "LA8",
		2: "R8",
		3: "RG8",
		4: "RGB8",
		5: "RGBA8",
		6: "RGBA4444",
		7: "RGBA5551",
		8: "RF",
		9: "RGF",
		10: "RGBF",
		11: "RGBAF",
		12: "RH",
		13: "RGH",
		14: "RGBH",
		15: "RGBAH",
		16: "RGBE9995",
		17: "DXT1",
		18: "DXT3",
		19: "DXT5",
		20: "RGTC_R",
		21: "RGTC_RG",
		22: "BPTC_RGBA",
		23: "BPTC_RGBF",
		24: "BPTC_RGBFU",
		25: "PVRTC2",
		26: "PVRTC2A",
		27: "PVRTC4",
		28: "PVRTC4A",
		29: "ETC",
		30: "ETC2_R11",
		31: "ETC2_R11S",
		32: "ETC2_RG11",
		33: "ETC2_RG11S",
		34: "ETC2_RGB8",
		35: "ETC2_RGBA8",
		36: "ETC2_RGB8A1",
	}
	var image_format_str = image_format_to_str_mapping.get(image.get_format(), "UNKNOWN")
	_stats_label.text = "w: {0}\nh: {1}\n{2}".format([image_size.x, image_size.y, image_format_str])


func _event_position_to_pixel_position(event_position):
	return (event_position / _zoom).floor()


func _fill_pixel(pixel_position, color):
	if (
		pixel_position.x < 0
		or pixel_position.x >= _image.get_size().x
		or pixel_position.y < 0
		or pixel_position.y >= _image.get_size().y
	):
		return
	var image = _local_texture.get_data()
	image.lock()
	image.set_pixelv(pixel_position, color)
	image.unlock()
	image_texture.set_data(image)
	_local_texture.set_data(image)
	image_texture.emit_changed()
	_local_texture.emit_changed()


func _draw_at_pos(event_position):
	var pixel_position = _event_position_to_pixel_position(event_position)
	_fill_pixel(pixel_position, _color_picker.color)


func _erase_at_pos(event_position):
	var pixel_position = _event_position_to_pixel_position(event_position)
	_fill_pixel(pixel_position, Color.transparent)


func _set_zoom(zoom, mark_altered):
	var zoom_before = _zoom
	_zoom = max(1, zoom)
	if mark_altered and _zoom != zoom_before:
		_zoom_altered = true
	_texture_rect.rect_min_size = _image.get_size() * _zoom
	_texture_rect.rect_size = _texture_rect.rect_min_size
	_texture_rect.material.set_shader_param("zoom", _zoom)
	_update_zoom_label()


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
	_set_zoom(_zoom + (1 if event.button_index == BUTTON_WHEEL_UP else -1), true)


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


func _on_panel_resized():
	if _zoom_altered:
		return
	var available_rect = _panel.rect_size
	if (
		available_rect.x <= RECT_MARGIN_FOR_INITIAL_ZOOM * 2
		and available_rect.y <= RECT_MARGIN_FOR_INITIAL_ZOOM * 2
	):
		available_rect -= Vector2(RECT_MARGIN_FOR_INITIAL_ZOOM, RECT_MARGIN_FOR_INITIAL_ZOOM) * 2
	var desired_zoom_xy = available_rect / _image.get_size()
	var desired_zoom = floor(min(desired_zoom_xy.x, desired_zoom_xy.y))
	_set_zoom(desired_zoom, false)


func _on_properties_button_pressed():
	_properties_window.image = _image
	_properties_window.popup_centered()


func _on_image_properties_changed(image):
	_image = image
	image_texture.create_from_image(_image, image_texture.flags)
	_local_texture.create_from_image(_image, _local_texture.flags)
	image_texture.emit_changed()
	_local_texture.emit_changed()
	_set_zoom(_zoom, false)
	_update_stats_label()
