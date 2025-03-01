extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		$"../YellowFlower3".visible = true
