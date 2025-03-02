extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Narkoman/CloseEyes/Eyes.play_backwards("close")
	$sounds/bee.playing = true

func _on_music_detect_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
