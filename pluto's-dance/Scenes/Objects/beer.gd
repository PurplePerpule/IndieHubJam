extends RigidBody3D

func pickable():
	$Cube_007.visible = false
	
func throw():
	$Cube_007.visible = true
