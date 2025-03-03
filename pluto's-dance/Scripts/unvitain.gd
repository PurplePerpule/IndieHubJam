extends RigidBody3D



func interact():
	$"..".state2 = false
	$"../Narkoman/CloseEyes/Eyes".play("close")
	$AudioStreamPlayer3D.playing = true
	await get_tree().create_timer(2).timeout
	LevelManager.load_level("res://Scenes/dripscene/dream_lvl_1.tscn")
