extends Node3D

var state1 = false
@export var state2 = true


func _ready() -> void:
	GlobalAudioServer.change_volume.connect(change_volume_f)
	GlobalAudioServer.change_music.connect(change_music_f)
	
	GlobalAudioServer.emit_signal("get_sound")
	
	
func change_volume_f(value):
	$sound/AudioStreamPlayer3D.volume_db = value + 7
	$Unvitain/AudioStreamPlayer3D.volume_db = value + 7
	
	
func change_music_f(value):
	$sound/AudioStreamPlayer.volume_db = value + 7


func _physics_process(delta: float) -> void:
	if state1 == false:
		$Narkoman/CloseEyes/Eyes.play_backwards("close")
		state1 = true
	
	if state2 == false:
		$Narkoman/CloseEyes/Eyes.play("close")
		state2 = true
