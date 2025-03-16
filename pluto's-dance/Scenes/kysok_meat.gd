extends Node3D

func _ready() -> void:
	$AnimationPlayer.play("movemeat")

func _physics_process(delta: float) -> void:
	pass
