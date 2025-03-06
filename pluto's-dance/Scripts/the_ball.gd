extends RigidBody3D

func pickable():
	$Cube2.visible = false
	
func throw():
	$Cube2.visible = true
