extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		await get_tree().create_timer(1.5).timeout
		$"../Narkoman/CloseEyes/Eyes".play("close")
		await get_tree().create_timer(1.5).timeout
		LevelManager.load_level("res://Interface/Titles/titles.tscn")
