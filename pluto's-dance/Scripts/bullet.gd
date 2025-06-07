extends RigidBody3D

@export var damage: float = 10.0

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	#queue_free() # Удаляем пулю после столкновения
