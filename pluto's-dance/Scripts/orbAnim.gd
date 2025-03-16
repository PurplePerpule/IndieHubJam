extends Node3D

@export var state_animation = 1

func _physics_process(delta: float) -> void:
	if state_animation == 1:
		$Animationorb.play("heartbit")
	if state_animation == 2:
		$Animationorb.play("state2")
