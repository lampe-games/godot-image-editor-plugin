tool
extends Control

export(ImageTexture) var image_texture = null

var is_standalone = true

var _image_size = null
var _zoom = 1
var _dragging = false
var _mode = 'draw'
var _previous_mode = 'draw'

onready var _texture_rect = find_node("TextureRect")
onready var _scroll_container = find_node("ScrollContainer")
# onready var _grid_overlay = find_node("GridOverlay")


func _ready():
	if Engine.editor_hint and is_standalone:
		return
	_texture_rect.texture = image_texture
	# _grid_overlay.texture = image_texture
	_image_size = image_texture.get_size()
	assert(_image_size != Vector2.ZERO)
	yield(get_tree(), "idle_frame")
	#print(_texture_rect.rect_size)
	assert(_image_size == _texture_rect.rect_size)
	find_node("Label").text = _mode


#func _force_color(color):
#	var texture = find_node("TextureRect").texture
#	if texture != null:
#		var image = texture.get_data()
#		image.lock()
#		var cnt = 0
#		for x in range(image.get_size().x):
#			for y in range(image.get_size().y):
#				if image.get_pixel(x, y).a > 0.0:
#					image.set_pixel(x, y, color)
#					if cnt == 0:
#						print(image.get_pixel(x, y))
#					cnt += 1
#		image.unlock()
#		print('done, cnt=', cnt)
#		#image.emit_changed()
#		texture.set_data(image)
##		texture.emit_changed()
##		var flags = texture.flags
##		texture.flags = Texture.FLAGS_DEFAULT
##		texture.emit_changed()
#		#texture.flags = flags
#		#texture.emit_changed()
#		#editor_interface.save_scene()


func _on_texture_rect_gui_input(event):
	if event is InputEventMouseMotion and _dragging:
		_scroll_container.scroll_horizontal -= event.relative.x
		_scroll_container.scroll_vertical -= event.relative.y
		return
	if not event is InputEventMouseButton:
		return
	if not event.is_pressed() and event.button_index == BUTTON_LEFT:
		if _mode == 'draw':
			print('d', event.position)
	elif event.is_pressed() and event.button_index == BUTTON_WHEEL_UP:
		_zoom += 1
		_texture_rect.rect_size = _image_size * _zoom
		_texture_rect.rect_min_size = _texture_rect.rect_size
		_texture_rect.material.set_shader_param('zoom', _zoom)
	elif event.is_pressed() and event.button_index == BUTTON_WHEEL_DOWN:
		_zoom = max(1, _zoom - 1)
		_texture_rect.rect_min_size = _image_size * _zoom
		_texture_rect.rect_size = _texture_rect.rect_min_size
		_texture_rect.material.set_shader_param('zoom', _zoom)
	elif event.is_pressed() and event.button_index == BUTTON_MIDDLE:
		_dragging = true
	elif not event.is_pressed() and event.button_index == BUTTON_MIDDLE:
		_dragging = false
	get_tree().set_input_as_handled()


func _on_draw_button_pressed():
	_mode = "draw"
	find_node("Label").text = _mode
	pass # Replace with function body.


func _on_erase_button_pressed():
	_mode = "erase"
	find_node("Label").text = _mode
	pass # Replace with function body.


func _on_color_picker_created():
	_mode = "pick"
	find_node("Label").text = _mode
	pass # Replace with function body.


func _on_color_picker_closed():
	_mode = "xxx"
	find_node("Label").text = _mode
	pass # Replace with function body.
