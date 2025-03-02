extends StaticBody3D
var is_open = false



func interact():
	
	if not is_open and $"../../../../../BeeMan".flowerfind >= 3:
		$"../../../../AnimationPlayer".play('open')
		$"../../../../../Narkoman/CloseEyes/Eyes".play("close")
		await get_tree().create_timer(1).timeout
		get_tree().change_scene_to_file("res://level/level_2.tscn")
		is_open = true
