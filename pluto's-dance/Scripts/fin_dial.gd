extends Area3D

var flag = false

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and flag == false:
		Dialogic.start("Final")
		Dialogic.timeline_ended.connect(final)
		flag = true
		
func final():
	Dialogic.timeline_ended.connect(final)
	$"../../StaticBody3D/CollisionShape3D".disabled = true
	$"../AnimationPlayer".play("end")
	
