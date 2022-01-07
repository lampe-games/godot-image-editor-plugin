tool
extends Control

export(ImageTexture) var image_texture = null

var is_standalone = true

onready var _texture_rect = find_node("TextureRect")

func _ready():
	if Engine.editor_hint and is_standalone:
		return
	_texture_rect.texture = image_texture
	yield(get_tree(), 'idle_frame')
	print(_texture_rect.rect_size)


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


func _on_3x_button_pressed():
	_texture_rect.rect_size *= 3
	_texture_rect.rect_min_size = _texture_rect.rect_size
	print(_texture_rect.rect_size)
	pass # Replace with function body.
