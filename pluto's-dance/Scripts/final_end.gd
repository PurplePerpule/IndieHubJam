extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		$"../Narkoman/CloseEyes/Eyes".play("close")
		await get_tree().create_timer(1).timeout
		get_tree().change_scene_to_file("res://level/main_menu_3d.tscn")
