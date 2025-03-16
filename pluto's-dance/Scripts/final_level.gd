extends Node3D


func _ready() -> void:
	$Narkoman/CloseEyes/Eyes.play_backwards("close")
	
	GlobalAudioServer.change_music.connect(change_music_f)
	
	GlobalAudioServer.emit_signal("get_sound")
	

func change_music_f(value):
	$sound/final.volume_db = value + 7
	$sound/hunt.volume_db = value + 7

func sound_start():
	$Sound/heart.playing = true
