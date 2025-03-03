extends Control


func _ready() -> void:
	$AnimationPlayer.play("fade")
	await get_tree().create_timer(1.5).timeout
	$AnimationPlayer.play_backwards("fade")
	await get_tree().create_timer(1).timeout
	LevelManager.load_level("res://level/level_1.tscn")
