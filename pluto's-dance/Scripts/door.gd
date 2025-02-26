extends StaticBody3D
var is_open = false

func interact():
	if not is_open:
		$"../../../../AnimationPlayer".play('open')
		is_open = true
	else:
		$"../../../../AnimationPlayer".play_backwards("open")
		is_open = false
