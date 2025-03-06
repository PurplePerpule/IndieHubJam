extends StaticBody3D

var take = false

func interact():
	if take == false: 
		$"../BeeMan".flowerfind += 1
		visible = false
		take = true


func _physics_process(delta: float) -> void:
	$AnimationPlayer.play("up")
	$Cube.rotation.y += delta
