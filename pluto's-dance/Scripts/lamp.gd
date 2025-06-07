extends RigidBody3D

func pickable():
	pass

func throw():
	pass

func toggle_light():
	if $OmniLight3D.visible == false:
		$OmniLight3D.visible = true
	else:
		$OmniLight3D.visible = false
		
func adjust_brightness():
	print("Lantern adjusts brightness!")
