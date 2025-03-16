extends Node3D


func _ready() -> void:
	$Narkoman/CloseEyes/Eyes.play_backwards("close")
	$Sounds/winert.volume_db = -20
	
	GlobalAudioServer.change_music.connect(change_music_f)
	
	GlobalAudioServer.emit_signal("get_sound")
	
	
func change_music_f(value):
	$Sounds/winert.volume_db = value + 7
