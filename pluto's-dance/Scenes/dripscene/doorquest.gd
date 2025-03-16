extends StaticBody3D
var is_open = false

var flag = false

func interact():
	if flag == false:
		flag = true
		Dialogic.start("res://Dialogs/door.dtl")
	
	if not is_open and $"../../../../../BeeMan".flowerfind >= 3:
		$"../../../../AnimationPlayer".play('open')
		$"../../../../../Narkoman/CloseEyes/Eyes".play("close")
		await get_tree().create_timer(1).timeout
		LevelManager.load_level("res://level/level_2.tscn")
		is_open = true
