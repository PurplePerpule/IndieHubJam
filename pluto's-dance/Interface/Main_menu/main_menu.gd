extends Control

@onready var Settings = $B_Settings
@onready var Play = $B_Settings
@onready var Exit = $B_Settings

func _ready():
	Settings.visible = false


func _on_play_pressed() -> void:
	pass # Replace with function body.


func _on_settings_pressed() -> void:
	Settings.visible = true
	Play.visible = false
	$MarginContainer/VBoxContainer/Settings.visible = false
	Exit.visible = false


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	Settings.visible = false
	Play.visible = true
	$MarginContainer/VBoxContainer/Settings.visible = true
	Exit.visible = true
