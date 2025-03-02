extends RigidBody3D


"res://Scenes/dripscene/dream_lvl_1.tscn"
func interact():
	$"..".state2 = false
	$"../Narkoman/CloseEyes/Eyes".play("close")
	$AudioStreamPlayer3D.playing = true
	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://Scenes/dripscene/dream_lvl_1.tscn")
