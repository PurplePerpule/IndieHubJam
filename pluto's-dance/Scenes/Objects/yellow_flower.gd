extends StaticBody3D

var take = false

func interact():
	if take == false: 
		$"../BeeMan".flowerfind += 1
		visible = false
		take = true
