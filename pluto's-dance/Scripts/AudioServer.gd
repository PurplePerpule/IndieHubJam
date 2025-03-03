extends Node

signal change_volume(value)
signal change_music(value)

signal get_sound()

var test_settings = load("res://Assets/Sounds/StreetAmbient_normal.ogg") #переменная для теста настроек звука


func _ready():
	change_volume.connect(change_volume_f)
	change_music.connect(change_music_f)
	
	#$Music.stream = test_settings
	#$Music.play()
	
	first_set()
	
	
func first_set():
	var volume_db = lerp(-40.0, 0.0, 40 / 100.0)  # Преобразуем значение ползунка в дБ
	emit_signal("change_music", volume_db)
	emit_signal("change_volume", volume_db)
	
	
func change_volume_f(value):
	$Volume.volume_db = value + 15
	
	
func change_music_f(value):
	$Music.volume_db = value + 15
