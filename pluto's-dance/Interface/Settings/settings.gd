extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_volume_value_changed(value):
	print("volume - " + str(value))


func _on_music_value_changed(value):
	print("music - " + str(value))


func _on_fullscreen_toggled(toggled_on):
	print("Fullscreen - " + str(toggled_on))
	
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
