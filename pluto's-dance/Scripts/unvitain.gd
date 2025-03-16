extends RigidBody3D


var flag = false
func interact():
	if flag == false:
		flag = true
		$"..".state2 = false
		$"../Narkoman/CloseEyes/Eyes".play("close")
		$AudioStreamPlayer3D.playing = true
		await get_tree().create_timer(2).timeout
		LevelManager.load_level("res://Scenes/dripscene/dream_lvl_1.tscn")
