extends Area3D

var flag = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and flag == false:
		flag = true
		$"../../sound/heart".volume_db = -15
		$"../../Mouth/AudioStreamPlayer3D".volume_db = 30
		$"../../sound/hunt".playing = true
