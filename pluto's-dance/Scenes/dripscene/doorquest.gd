extends StaticBody3D
var is_open = false



func interact():
	
	if not is_open and $"../../../../../BeeMan".flowerfind >= 3:
		$"../../../../AnimationPlayer".play('open')
		is_open = true
