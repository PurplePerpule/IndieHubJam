extends Area3D

var flag = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and flag == false:
		flag = true
		Dialogic.start("Final")
		Dialogic.timeline_ended.connect(final)
		
func final():
	Dialogic.timeline_ended.disconnect(final)
	$"../partlest/TheFace/StaticBody3D/CollisionShape3D".disabled = true
	$"../partlest/TheFace/AnimationPlayer".play("end")
	
