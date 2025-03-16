extends RigidBody3D


func interact():
	await get_tree().create_timer(1.5).timeout
	$"../../Narkoman/CloseEyes/Eyes".play("close")
	await get_tree().create_timer(1.5).timeout
	LevelManager.load_level("res://Interface/Titles/titles.tscn")
