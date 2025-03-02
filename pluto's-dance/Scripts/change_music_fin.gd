extends Area3D

var flag = false

func _ready() -> void:
	$"../sound/hunt".playing = true
	


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and flag == false:
		flag = true
		$"../Mouth".queue_free()
		$"../sound/hunt".playing = false
		$"../sound/final".playing = true
