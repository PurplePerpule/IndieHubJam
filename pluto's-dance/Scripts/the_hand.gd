extends Node3D


func _physics_process(delta: float) -> void:
	$AnimationPlayer.play("idle")
