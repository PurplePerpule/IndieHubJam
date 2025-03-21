extends Control

@onready var Settings = $B_Settings
@onready var Main = $Main

func _ready():
	Settings.visible = false
	Main.visible = true


func _on_play_pressed() -> void:
	LevelManager.load_level("res://Scenes/intro.tscn")


func _on_settings_pressed() -> void:
	Settings.visible = true
	Main.visible = false
	GlobalAudioServer.emit_signal("move_sliders")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	Settings.visible = false
	Main.visible = true
