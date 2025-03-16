extends Area3D

var flag = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and flag == false:
		flag = true
		$"../sound/hunt".playing = false
		$"../sound/final".playing = true
		$"../Mouth".queue_free()
		$"../Mouth2".queue_free()
		$"../EnvObj".queue_free()
		$"../MoveWAll".queue_free()
