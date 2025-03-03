extends Control

@onready var fullscreen = $MarginContainer/VBoxContainer/Fullscreen
@onready var music = $MarginContainer/VBoxContainer/Music
@onready var volume = $MarginContainer/VBoxContainer/Volume
@onready var sensitivity = $MarginContainer/VBoxContainer/Sensitivity


func _ready() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		fullscreen.button_pressed = true
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
	#GlobalAudioServer.emit_signal("change_music", lerp(-40.0, 0.0, music.value / 100.0))
	#GlobalAudioServer.emit_signal("change_volume", lerp(-40.0, 0.0, volume.value / 100.0))
	
	Data.emit_signal("change_sensitivity", sensitivity.value)
	
	GlobalAudioServer.get_sound.connect(get_value)


func _on_volume_value_changed(value):
	var volume_db = lerp(-40.0, 0.0, value / 100.0)  # Преобразуем значение ползунка в дБ
	GlobalAudioServer.emit_signal("change_volume", volume_db)


func _on_music_value_changed(value: float):
	var volume_db = lerp(-40.0, 0.0, value / 100.0)  # Преобразуем значение ползунка в дБ
	GlobalAudioServer.emit_signal("change_music", volume_db)  # Передаем громкость в дБ


func _on_fullscreen_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_sensitivity_value_changed(value: float) -> void:
	Data.emit_signal("change_sensitivity", value / 135)
	
	
func get_value():
	print(123)
	var music_db = lerp(-40.0, 0.0, music.value / 100.0)  # Преобразуем значение ползунка в дБ
	GlobalAudioServer.emit_signal("change_music", music_db)  # Передаем громкость в дБ
	
	var volume_db = lerp(-40.0, 0.0, volume.value / 100.0)  # Преобразуем значение ползунка в дБ
	GlobalAudioServer.emit_signal("change_volume", volume_db)
	
