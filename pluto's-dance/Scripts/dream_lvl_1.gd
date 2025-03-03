extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Narkoman/CloseEyes/Eyes.play_backwards("close")
	$sounds/bee.playing = true
	
	GlobalAudioServer.change_volume.connect(change_volume_f)
	GlobalAudioServer.change_music.connect(change_music_f)
	
	
func change_volume_f(value):
	$sounds/bee.volume_db = value + 15
	
	
func change_music_f(value):
	$sounds/Happy.volume_db = value + 15
