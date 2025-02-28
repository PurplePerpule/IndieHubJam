extends Node3D

var state1 = false
@export var state2 = true




func _physics_process(delta: float) -> void:
	if state1 == false:
		$Narkoman/CloseEyes/Eyes.play_backwards("close")
		state1 = true
	
	if state2 == false:
		$Narkoman/CloseEyes/Eyes.play("close")
		state2 = true
