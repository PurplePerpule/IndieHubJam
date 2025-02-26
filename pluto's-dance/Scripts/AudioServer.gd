extends Node

signal change_volume(value)
signal change_music(value)

var test_settings = load("res://Assets/Sounds/StreetAmbient_normal.ogg") #переменная для теста настроек звука


func _ready():
	change_volume.connect(change_volume_f)
	change_music.connect(change_music_f)
	
	$Music.stream = test_settings
	$Music.play()
	
	
func change_volume_f(value):
	$Volume.volume_db = value + 15
	
	
func change_music_f(value):
	$Music.volume_db = value + 15
